```markdown
# Apache Tomcat Setup & Jenkins CI/CD Pipeline Deployment

---

## Phase 1: Infrastructure Setup via Terraform

- Provision an **EC2 instance** using a Terraform script as the host for the Tomcat server
- Attach the required **Security Groups** with the following inbound ports open:
  - Port **22** → SSH access
  - Port **8080** → Tomcat application access

---

## Phase 2: Tomcat Installation & Configuration

### 2.1 Initial Server Setup

- Connect to the EC2 instance via SSH and switch to the root user:
```bash
sudo su
```
- Navigate to the `/opt/` directory where Tomcat will be installed:
```bash
cd /opt/
```

### 2.2 Install Java (Prerequisite)
- Tomcat requires Java to run. Install it before proceeding:
```bash
sudo yum install java-11 -y
java -version
```

### 2.3 Download & Install Tomcat
- Download the Tomcat 10 binary:
```bash
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.52/bin/apache-tomcat-10.1.52.tar.gz
```
- Extract the downloaded archive:
```bash
tar -zvxf apache-tomcat-10.1.52.tar.gz
```
- Delete the zip file after extraction:
```bash
rm -f apache-tomcat-10.1.52.tar.gz
```

### 2.4 Start Tomcat Service
- Navigate to the Tomcat `bin/` directory:
```bash
cd /opt/apache-tomcat-10.1.52/bin/
```
- Check Tomcat version and environment details:
```bash
sh version.sh
```
- Start the Tomcat service:
```bash
# Linux
sh startup.sh

# Windows
sh startup.bat
```

> 💡 **Tip — Finding any file in the system:**
> ```bash
> find / -name <filename>
> # Example:
> find / -name context.xml
> ```

---

### 2.5 Enable Remote Access to Tomcat Manager

> By default, Tomcat restricts Manager and Host-Manager access to `localhost` only.
> Since we are accessing it remotely, we need to comment out the IP restriction in two files.

- Edit the **Host Manager** context file:
```bash
vim /opt/apache-tomcat-10.1.52/webapps/host-manager/META-INF/context.xml
```
- Edit the **Manager** context file:
```bash
vim /opt/apache-tomcat-10.1.52/webapps/manager/META-INF/context.xml
```
- In **both files**, comment out the following block:
```xml
<!-- <Valve className="org.apache.catalina.valves.RemoteCIDRValve"
       allow="127.0.0.0/8,::1/128" /> -->
```

---

### 2.6 Configure Tomcat User Roles

- Open the Tomcat users config file:
```bash
vim /opt/apache-tomcat-10.1.52/conf/tomcat-users.xml
```
- Add the following roles and admin user before the closing `</tomcat-users>` tag:
```xml
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<role rolename="admin-gui"/>
<role rolename="admin-status"/>

<user username="admin" password="admin"
  roles="admin-gui,manager-gui,manager-script,manager-status"/>
```

---

### 2.7 (Optional) Create Softlinks for Easy Service Management

- Run the following from the `bin/` directory to create shortcut commands:
```bash
ln -s /opt/apache-tomcat-10.1.52/bin/startup.sh /usr/bin/tomcatstart
ln -s /opt/apache-tomcat-10.1.52/bin/shutdown.sh /usr/bin/tomcatstop
```
- Now you can start or stop Tomcat from anywhere:
```bash
tomcatstart
tomcatstop
```

---

## Phase 3: Jenkins CI/CD Pipeline Setup

> Tomcat is now running on the EC2 instance. This phase connects Jenkins to GitHub
> and automates the build and deployment of a Maven-based Spring Boot application to Tomcat.

---

### 3.1 Install Required Jenkins Plugins

Go to **Jenkins Dashboard → Manage Jenkins → Plugins** and install:
- `Maven Integration` — enables Maven build projects in Jenkins
- `Deploy to Container` — enables WAR file deployment to Tomcat from Jenkins

---

### 3.2 Add Tomcat Credentials in Jenkins

Navigate to: **Jenkins Dashboard → Credentials → System → Global → Add Credentials**

| Field | Value |
|---|---|
| Kind | Username with password |
| Username | `admin` |
| Password | `admin` |
| ID | `tomcat-user` |
| Description | `tomcat-user` |

---

### 3.3 Create the Jenkins Pipeline

**i. Create a New Job:**
- Click **New Item** → Select **Maven Project** → Give it a name

**ii. Configure Source Code (Git):**
- Under **Source Code Management**, select **Git**
- Enter the repository URL:
```
https://github.com/Saahiti-Korlam/maven-new-springboot.git
```
- Specify the branch (e.g., `main` or `master`)

**iii. Configure Build Steps:**
- Root POM:
```
pom.xml
```
- Goals and Options:
```
clean install package
```

**iv. Configure Post-Build Actions (Deployment):**
- Select **Deploy WAR/EAR to a container**
- WAR file pattern:
```
**/*.war
```
- Click **Add Container** → Select **Tomcat 9.x**
- Fill in the following:
  - **Credentials** → select `tomcat-user` (admin/admin)
  - **Tomcat URL** → `http://65.2.37.41:8080/`

- Click **Save** → Click **Build Now**

---

## Phase 4: Verify Deployment

- Once the Jenkins build succeeds, open a browser and navigate to:
```
http://65.2.37.41:8080/
```
- Go to the **Tomcat Web Manager** — the deployed application will be listed
- Click on the application → the web page loads with:
```
WELCOME TO PIPELINE
```

---

## Summary

| Phase | What Was Done |
|---|---|
| Infrastructure | EC2 provisioned via Terraform with ports 22 & 8080 open |
| Tomcat Setup | Installed, configured roles, enabled remote access |
| Jenkins Config | Plugins installed, credentials added, pipeline created |
| CI/CD Flow | GitHub → Jenkins (Maven build) → WAR deployed to Tomcat |
| Result | Live app accessible via EC2 public IP on port 8080 |
```
