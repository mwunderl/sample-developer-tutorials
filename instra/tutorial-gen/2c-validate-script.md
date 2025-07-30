
# static analysis

After you've confirmed that the script is functional, perform a thorough static analysis of the provided shell script without executing it. Focus on identifying potential issues in the following categories:

1. Resource Dependencies and Sequencing:
   - Identify operations that create dependencies between resources
   - Verify that resources are created in the correct order
   - Check for operations that modify the same resource multiple times
   - Flag any attempts to associate resources that might already have existing associations

2. Error Handling and Resilience:
   - Evaluate error handling mechanisms
   - Check for proper exit strategies when commands fail
   - Identify sections that might leave resources in an inconsistent state
   - Verify cleanup procedures are comprehensive and properly sequenced

3. Security and Best Practices:
   - Identify overly permissive security configurations
   - Flag hardcoded credentials or sensitive information
   - Check for adherence to infrastructure-as-code best practices
   - Verify proper resource tagging and naming conventions

4. Resource Limitations:
   - Identify potential service quotas or limits that might be exceeded
   - Check for resource creation without corresponding cleanup
   - Flag operations that might incur unexpected costs

5. Logic and Control Flow:
   - Analyze conditional logic for potential flaws
   - Verify loop constructs for proper termination conditions
   - Check for race conditions or timing issues
   - Identify potential infinite loops or deadlocks

6. AWS-Specific Concerns (for AWS scripts):
   - Verify proper handling of AWS region settings
   - Check for proper IAM permissions and least privilege principles
   - Identify potential cross-region or cross-account issues
   - Verify proper handling of AWS resource identifiers

## Output Files and Response Format

When validating a script, create the following output files:

1. Validation Report File:
   - Name: `[original-script-name]-validation-report.md`
   - Content: Detailed analysis of issues found in the script
   - Location: Save in the validation-tools directory

2. Fixed Script File (ONLY if HIGH severity issues are found):
   - Name: `[original-script-name]-fixed.sh`
   - Content: Complete fixed version of the script with comments explaining changes
   - Location: Save in the validation-tools directory

3. Response to User:
   - Provide a brief summary of the validation results
   - Include the number and types of issues found (High/Medium/Low)
   - Clearly state which issues will be fixed (HIGH severity) and which won't be fixed (MEDIUM and LOW severity)
   - Mention that the detailed report and fixed script (if applicable) have been saved as files
   - DO NOT include the entire fixed script in your response to the user

The validation report should include:
- A summary of potential issues categorized by severity (High, Medium, Low)
- Clear distinction between issues that will be fixed in the fixed script (HIGH severity) and those that won't be fixed (MEDIUM and LOW severity)
- Line numbers or code snippets where issues were found
- Specific recommendations for addressing each issue
- Suggestions for improving the overall script quality and reliability

In the fixed script:
- Add comments before each fixed section explaining what HIGH severity issue is being addressed
- Include a header comment summarizing all HIGH severity issues that were fixed
- Optionally include comments about MEDIUM and LOW severity issues that weren't fixed but could be improved in the future

## File Organization

- If validation reports and fixed scripts already exist for the script being validated, move the existing files to the `archive` directory before creating new ones
- This ensures that the main directory contains only the most recent validation results while preserving previous work

This naming convention ensures clear association between original scripts, validation reports, and fixed versions.
