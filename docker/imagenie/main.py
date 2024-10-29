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

        # Check the return code and act accordingly
        if scan_result.returncode == 0:
            print(f"No vulnerabilities found for {container_name}. Proceeding with conversion.")
            sif_file = f"/tmp/{container_name}.sif"
            subprocess.run(["singularity", "build", sif_file, f"docker-archive:{staging_path}"])
    
            # Upload .sif to the production bucket
            destination_blob = production_bucket.blob(f"containers/{container_name}.sif")
            destination_blob.upload_from_filename(sif_file)
            print(f"{container_name} has been converted and uploaded successfully.")
    
        elif scan_result.returncode == 1:
            print(f"Vulnerabilities found in {container_name}, but none are critical.")
        else:
            # Handle critical vulnerabilities or errors
            if scan_result.returncode == 2:
                logging.error(f"Critical vulnerabilities found in {container_name}:\n{scan_result.stdout}")
                # Notify the relevant team/person about critical vulnerabilities
            else:
                logging.error(f"Error scanning image {container_name}: {scan_result.stderr}")
    
        # Additional logging for debugging
        logging.debug(f"Scan result for {container_name} stdout: {scan_result.stdout}")
        logging.debug(f"Scan result for {container_name} stderr: {scan_result.stderr}")
    return "Processing complete."

if __name__ == "__main__":
    process_containers()

