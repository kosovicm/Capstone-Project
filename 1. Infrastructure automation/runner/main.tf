provider "google" {
  project     = "sage-byte-466314-e8"
  region  = "us-central1"
  zone    = "us-central1-a"
  credentials = file("/home/kosovicm/Desktop/serviceaccount.json") ### ZAMENITI ZA IAM, WORKLOAD pogledati sta je rekla svetlana
}

variable "github_token" {
  type = string
  sensitive = true
}


resource "google_compute_instance" "github_runner" {
  name         = "vm-for-runner"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }
  metadata_startup_script = format(<<EOF
        #!/bin/bash

        # Instalacija zavisnosti i Docker repoa
        apt-get update
        apt-get install -y curl gnupg lsb-release git unzip

            # Install Node.js LTS (18.x)
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
        
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo \
          "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
            $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io

        # Kreiranje korisnika
        useradd -m runner
        usermod -aG docker runner
        cd /home/runner

        # Download GitHub Actions Runner
        curl -o actions-runner-linux-x64-2.326.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.326.0/actions-runner-linux-x64-2.326.0.tar.gz
        echo "9c74af9b4352bbc99aecc7353b47bcdfcd1b2a0f6d15af54a99f54a0c14a1de8  actions-runner-linux-x64-2.326.0.tar.gz" | shasum -a 256 -c
        tar xzf actions-runner-linux-x64-2.326.0.tar.gz
        chown -R runner:runner /home/runner

        su - runner -c "cd /home/runner && ./config.sh --url https://github.com/kosovicm/Terraform-zadatak --token %s --unattended --labels gcp-runner"
        su - runner -c "cd /home/runner && ./svc.sh install"
        su - runner -c "cd /home/runner && ./svc.sh start"
        su - runner -c "./run.sh"
  EOF
  , var.github_token)
}