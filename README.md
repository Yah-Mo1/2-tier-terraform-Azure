# 🚀 Azure 2-Tier Architecture with Terraform

## 📌 Overview

I have used **Terraform** to provision a **2-tier infrastructure** in **Microsoft Azure**, consisting of:

- A **private database virtual machine (DB VM)** running MongoDB.
- A **public-facing application virtual machine (App VM)** running a Node.js application.
- Networking components such as a **Virtual Network (VNet)**, **Subnets**, **Security Groups**, and a **Public IP**.

This setup ensures that the **DB VM remains private**, only accessible by the **App VM**, which is public-facing and serves web traffic.

---

## 🏗️ Infrastructure Details

### **1️⃣ Database Virtual Machine (DB VM)**

- I deployed a **private Linux VM** to host a MongoDB database.
- This VM is placed inside a **private subnet**, meaning it has **no public IP** and cannot be accessed from the internet.
- The **private IP is dynamically assigned** and referenced in the **App VM** environment variables.
- The VM uses a **custom image** (`tech501-ramon-sparta-app-ready-to-run-db`) to ensure MongoDB is pre-installed.

### **2️⃣ Application Virtual Machine (App VM)**

- I deployed a **public-facing Linux VM** to host my Node.js application.
- This VM is placed inside a **public subnet** and has a **public IP**, allowing access from the internet.
- The application automatically **retrieves the private IP of the DB VM** and connects to MongoDB securely.
- The VM uses a **custom image** (`tech501-ramon-sparta-test-app-ready-to-run-app`) to ensure the application is pre-configured.
- Environment variables are set using **Terraform’s `custom_data`** feature, allowing seamless connectivity.

### **3️⃣ Networking & Security**

- I created a **Virtual Network (VNet)** with both **public and private subnets**.
- The **DB VM is only accessible from within the private subnet**, ensuring database security.
- The **App VM has an NSG (Network Security Group)** that only allows **SSH (port 22)** and **HTTP (port 80)** traffic.
- Outbound internet access is enabled for necessary updates and package installations.

---
