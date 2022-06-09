# Example of github action pipeline

The pipeline invokes linting and testing for pull requests to the repository.
After the merge, it publishes part of the code to another [repository](https://github.com/khevse/ci-target).

# Required
1. Create [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
2. Go to the Github page for the repository that you push from, click on "Settings"
3. On the left hand side pane click on "Secrets"
4. Click on "Add a new secret" and name it **API_TOKEN_GITHUB**

