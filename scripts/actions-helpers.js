const fs = require('fs')

const maxOutputLength = 200000
const stepOutcomeIcons = {
  success: '🟢',
  failure: '🔴',
  skipped: '⚪',
  pending: '🟡',
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
  const outcome =
    step.outcome ||
    process.env[`STEP_${stepName.toUpperCase().replaceAll('-', '_')}_OUTCOME`] ||
    'unknown'
  const outcomeIcon = stepOutcomeIcons[outcome] || stepOutcomeIcons.unknown
  const stepOutput = buildStepOutput(context, core, stepName)

  let stepSummaryText = `${outcomeIcon} <strong>${step.label || `terraform ${stepName}`}</strong>`

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
    return ''
  }

  const line = output.split('\n').find((l) => l.startsWith('Plan: '))
  if (!line) {
    core.debug('Did not find a plan summary - returning "0 changes"')
    return '0 changes'
  }

  core.debug(`Plan summary = ${line}`)
  return line.replace(/^Plan:\s*/, '').replace(/\.$/, '')
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

module.exports = {
  buildComment,
}
