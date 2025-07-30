# validate tutorial

Validating the content of the AWS CLI tutorial and surface issues about the generated content.

## deprecated features

Generate a list of service features used in the tutorial. Store this list in 3-features.md, with the name of the service above the list. If there are multiple services used, include a separate list for each service.

Check the documentation for each feature and determine when the feature was released, when it was last updated, and whether it is deprecated. A feature can be marked deprecated, legacy, or not recommended in the feature guidance, API reference, or doc history topic. Each service guide has a doc history topic that has entries for service releases that had documentation updates. Some are more extensive than others. If you can't find all of the information for every feature that's ok. If a feature is deprecated, legacy, or not recommend, figure out which feature to use instead. There should be guidance on how to migrate from the old feature to the new one.

Capture all of this information in a CSV file named 3-features.csv with an entry for each feature and columns for service_name, feature_name, release_date, last_up_dated, deprecated_bool, replaced_by. For any deprecated features included in the tutorial, capture this information in an error report in 3-errors.md. Each error should have a separate entry with a header indicating the issue, a description, and links to relevant documentation.

## expensive resources

Check the pricing page for the service to determine the cost of running all of the resources created in the tutorial for one hour. Note the cost of each feature and the total cost for the tutorial in 3-cost.md. 

## unsecured resources

Check the tutorial for security risks, such as too permissive resource-based policies, or wildcard use in permission scopes. Note any issues in 3-security.md.

## architecture best practices

Check the tutorial for issues from an application architecure standpoint. Consider the AWS Well-Architeced framework, noting issues that would prevent the solution described from scaling. Note any issues in 3-architecture.md.

## improvements over baseline

Review the baseline tutorial for errors and omissions that were fixed by following the authoring instructions, or caught by validation. Note any issues in 3-baseline.md.