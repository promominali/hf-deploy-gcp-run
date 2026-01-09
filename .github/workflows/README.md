## Setup Required
1. Service Account
	◦ Create a GCP service account with roles:
		▪︎ roles/run.admin
		▪︎ roles/artifactregistry.admin
		▪︎ roles/iam.serviceAccountUser
	◦ Download its JSON key.
2. GitHub Secret
	◦ In your repo → Settings → Secrets and variables → Actions.
	◦ Add a secret named GCP_SA_KEY with the JSON key contents.