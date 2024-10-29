import subprocess
import requests
import logging
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

    # Download the Trivy vulnerability database
    command = ["trivy", "--cache-dir", "/tmp/", "image", "--download-db-only"]
    try:
        download_result = subprocess.run(command, capture_output=True, text=True)
    
        # Check for success or error messages
        if download_result.returncode == 0:
            print("Vulnerability database downloaded successfully.")
        else:
            print(f"Error downloading database: {download_result.stderr}")
    
    except Exception as e:
        print(f"An error occurred: {e}")

    for container_name in container_names:
        image = f"docker://{org}/{container_name}:latest"
        staging_path = f"/tmp/{container_name}.tar"
        
        # Pull container to temporary storage
        subprocess.run(["skopeo", "copy", image, f"docker-archive:{staging_path}"])

        # Scan the image with Trivy
        scan_result = subprocess.run(
            [
                "trivy", "image", "--severity", "CRITICAL", "--debug", "--security-checks", "vuln",
                "--offline-scan", "--cache-dir", "/tmp/", "--input", staging_path
            ],
            capture_output=True, text=True
        )

        # Check if "CRITICAL" vulnerabilities were found
        if "CRITICAL" in scan_result.stdout:
            print(f"Critical vulnerabilities found in {container_name}. Skipping conversion and upload.")
            logging.error(f"Critical vulnerabilities detected in {container_name}.")
            subprocess.run(["rm", "-f", staging_path], check=True)
            continue  # Skip to the next container

        # If no critical vulnerabilities were found, proceed with .sif creation and upload
        print(f"No critical vulnerabilities found for {container_name}. Proceeding with conversion.")
        sif_file = f"/tmp/{container_name}.sif"
        subprocess.run(["singularity", "build", sif_file, f"docker-archive:{staging_path}"])
    
        # Upload .sif to the production bucket
        destination_blob = production_bucket.blob(f"containers/{container_name}.sif")
        destination_blob.upload_from_filename(sif_file)
        print(f"{container_name} has been converted and uploaded successfully.")
    
        # Clean up .sif and .tar files
        subprocess.run(["rm", "-f", sif_file, staging_path], check=True)
 
        # Additional logging for debugging
        logging.debug(f"Scan result for {container_name} stdout: {scan_result.stdout}")
        logging.debug(f"Scan result for {container_name} stderr: {scan_result.stderr}")
    return "Processing complete."

if __name__ == "__main__":
    process_containers()

