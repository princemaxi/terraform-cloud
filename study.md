# Additional Study

- Summarise your understanding on Networking concepts like IP Address, Subnets, CIDR Notation, IP Routing, Internet Gateways, NAT

    ## Networking Concepts

    - IP Address: A unique identifier assigned to each device on a network, enabling communication. IPv4 uses 32 bits, IPv6 uses 128 bits.

    - Subnets: Logical subdivisions of a network, designed to organize devices and manage traffic efficiently.

    - CIDR Notation: Classless Inter-Domain Routing (e.g., 192.168.1.0/24) specifies IP ranges and subnet size.

    - IP Routing: The process of directing network packets from source to destination across interconnected networks using routing tables.

    - Internet Gateway (IGW): Connects a VPC to the internet, allowing instances in public subnets to send and receive traffic.

    - NAT (Network Address Translation): Enables instances in private subnets to access the internet securely without exposing their private IP addresses.

    Summary: Networking is about structuring IPs and subnets to efficiently route traffic, maintain security, and provide internet access through gateways and NATs.


- Summarise your understanding of the OSI Model, TCP/IP suite and how they are connected research beyond the provided articles, watch different YouTube videos to fully understand the concept around OSI and how it is related to the Internet and end-to-end Web Solutions. You do not need to memorise the layers - just understand the idea around it.

  - OSI Model: Conceptual framework with 7 layers (Physical → Application) that standardizes network communication. Helps understand where protocols and functions operate in a network.

  - TCP/IP Suite: Practical model used in the internet; it has 4 layers (Link, Internet, Transport, Application) that map roughly to OSI layers.

  - Connection to Internet & Web: OSI provides a theoretical view, TCP/IP is how data actually flows over the internet. Together, they explain how applications like web browsers communicate end-to-end reliably.

  Summary: OSI is a guide to understand networking layers; TCP/IP is the real-world implementation enabling reliable internet communication and end-to-end web solutions.

- Explain the difference between assume role policy and role policy

  - Assume Role Policy: Defines who or what can assume the role (e.g., EC2 instances, users, accounts). Essentially, it controls role access.

  - Role Policy: Defines what permissions the role has once assumed—what actions can be performed and on which resources.

  Summary: Assume Role Policy = “Who can use this role?”
  Role Policy = “What can this role do once assumed?”

