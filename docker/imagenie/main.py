import subprocess
import requests
from google.cloud import storage

def get_container_names(org):
    """Fetches container names from the specified Docker Hub organization."""
    url = f"https://hub.docker.com/v2/repositories/{org}/"
    container_names = []
    page = 1
    while True:
        response = requests.get(url, params={'page': page})
        if response.status_code != 200:
            break
        data = response.json()
        repositories = data.get('results', [])
        if not repositories:
            break
        for repo in repositories:
            container_names.append(repo['name'])
        page += 1
    return container_names

def process_containers():
    client = storage.Client()
    production_bucket = client.bucket("qmul-production-sandbox-1-red")

    org = "ghtrecontainers"
    container_names = get_container_names(org)  # Fetch container names from the organization

    for container_name in container_names:
        image = f"docker://{org}/{container_name}:latest"
        staging_path = f"/tmp/{container_name}.tar"
        
        # Pull container to temporary storage
        subprocess.run(["skopeo", "copy", image, f"docker-archive:{staging_path}"])

        # Scan the image with Trivy
        scan_result = subprocess.run(["trivy", "--exit-code", "1", "--severity", "CRITICAL", f"docker-archive:{staging_path}"],
                                     capture_output=True, text=True)
        
        # If no vulnerabilities found, proceed to convert and upload
        if scan_result.returncode == 0:
            sif_file = f"/tmp/{container_name}.sif"
            subprocess.run(["singularity", "build", sif_file, f"docker-archive:{staging_path}"])

            # Upload .sif to the production bucket
#            destination_blob = production_bucket.blob(f"containers/{container_name}.sif")
#            destination_blob.upload_from_filename(sif_file)
    
    return "Processing complete."

if __name__ == "__main__":
    process_containers()

