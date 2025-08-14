const fs = require('fs')

const maxOutputLength = 200000
const stepOutcomeIcons = {
  success: '🟢',
  failure: '🔴',
  skipped: '⚪',
  unknown: '❔',
}

const buildComment = ({context, core, command, configName, steps}) => {
  const filePath = `/tmp/${context.runId}.comment.txt`

  const commentBody = '### terraform ' + command + ': `' + configName + '`\n\n' +
    steps.map(step => buildStep(context, core, step)).join('\n\n') +
    `

---
[View the run details](${fetchJobLink(context)})`

  core.debug(`Comment: ${commentBody}`)

  try {
    fs.writeFileSync(filePath, commentBody)
  } catch (err) {
    core.setFailed(`Failed to write comment to ${filePath}: ${err}`)
  }

  return filePath
}

const buildStep = (context, core, step) => {
  const stepName = step.name
  const outcome = process.env[`STEP_${stepName.toUpperCase().replace('-', '_')}_OUTCOME`] || 'unknown'
  const outcomeIcon = stepOutcomeIcons[outcome] || stepOutcomeIcons.unknown
  const stepOutput = buildStepOutput(context, core, stepName)

  let stepSummaryText = `${outcomeIcon} <strong>terraform ${stepName}</strong>`

  if (stepName === 'plan') {
    const planSummary = extractPlanSummary(core, stepOutput)
    if (planSummary) {
      stepSummaryText += ` (${planSummary.trim()})`
    }
  }

  if (stepOutput) {
    return `<details>
<summary>${stepSummaryText}</summary>  

~~~
${stepOutput.trim()}
~~~             
</details>`
  }

  return `&nbsp;&nbsp;&nbsp;${stepSummaryText}`
}

const extractPlanSummary = (core, output) => {
  if (!output) {
    return '';
  }

  const planSummary = output
    .split('\n')
    .find(line => line.startsWith('Plan: ')) || '0 changes'

  if (planSummary === undefined) {
    core.debug('Did not find a plan summary - returning "0 changes"')
    return '0 changes'
  }

  core.debug(`Plan summary = ${planSummary}`)
  return planSummary.replace(/^Plan:/, '').replace(/\.$/, '')
}

const buildStepOutput = (context, core, stepName) => {
  try {
    let output = fs.readFileSync(`/tmp/${context.runId}.${stepName}.txt`, 'utf8')

    output = output
      .split('\n')
      .filter(function (line) {
        return !(
          line.includes('Reading...') ||
          line.includes('Read complete after') ||
          line.includes('Refreshing state...')
        )
      })
      .join('\n')

    if (output.length > maxOutputLength) {
      output = output.substring(0, maxOutputLength - 100)
      output += '\n\nOutput too long and has been truncated. View the full logs in GitHub actions.'
    }

    return output
  } catch (err) {
    core.warning(`Failed to read output of step ${stepName}: ${err}`)
    return ''
  }
}

const fetchJobLink = (context) => {
  return `https://github.com/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}?check_suite_focus=true`
}

const createStatusCheck = async ({ github, context, core, sha, state, targetUrl, checkContext }) => {
  const request = {
    owner: context.repo.owner,
    repo: context.repo.repo,
    sha,
    state,
    target_url: targetUrl,
    context: checkContext,
  }
  core.debug(`Commit status request: ${JSON.stringify(request)}`)

  try{
    await github.rest.repos.createCommitStatus(request)
  } catch (error) {
    core.setFailed(`Error creating commit status ${JSON.stringify(request)}: ${error}`)
  }
}

const handleApply = async ({github, context, core}) => {
  const postComment = (body) => github.rest.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
    body,
  })

  const user = context.payload.comment.user.login
  const config = context.payload.comment.body.replace(/^\/apply/, '').trim()
  core.debug(`User ${user} triggered apply for config: ${config}`)

  const pr = await github.rest.pulls.get({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: context.issue.number,
  })

  core.debug(`The status of PR ${context.issue.number} is ${pr.data.draft ? 'draft' : 'ready'}`)
  if (pr.data.draft) {
    postComment(`@${user} you cannot apply on a draft pull request.`)
    return core.setFailed('The pull request is in draft')
  }


  core.debug(`The state of PR ${context.issue.number} is ${pr.data.mergeable_state}`)
  if (pr.data.mergeable_state !== 'clean') {
    const permissionLevel = await github.rest.repos.getCollaboratorPermissionLevel({
      owner: context.repo.owner,
      repo: context.repo.repo,
      username: user,
    })

    if (permissionLevel.data.permission  === 'admin') {
      core.warning(`User @${user} is an admin so the approval check has been bypassed`)
    } else {
      postComment(`@${user}, you can only apply on pull requests that are mergeable.

Make sure all merge conflicts are resolved, all required status checks have passed and that the PR has been approved.`)
      return core.setFailed('The pull request is not mergeable')
    }
  }

  if (!config) {
    postComment('@' + user + ' you must specify the config you wish to apply (eg `/apply domain`).')
    return core.setFailed('Missing config')
  }

  if (!fs.existsSync(`configs/${config}/.terraform.lock.hcl`)) {
    core.debug(`File 'configs/${config}/.terraform.lock.hcl' does not exist.`)
    postComment('@' + user + ' the specified config (`' + config + '`) does not exist.')
    return core.setFailed(`Config '${config}' does not exist`)
  }

  core.setOutput('config', config)
}

module.exports = {
  buildComment,
  handleApply,
  createStatusCheck,
}
