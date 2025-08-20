# Production Global Infrastructure

This directory contains Terraform configurations for **production** global shared infrastructure components. These resources have **HIGH BLAST RADIUS** and require strict change management processes.

## ⚠️ CRITICAL WARNING ⚠️

**PRODUCTION ENVIRONMENT - HANDLE WITH EXTREME CARE**

- All changes require thorough testing in staging first
- Changes must be approved through formal change management process
- Deploy during maintenance windows only
- Have rollback plan prepared before any changes
- Monitor all resources after deployment

## Overview

The production global infrastructure provides:
- **High-availability VPC networks** across multiple regions
- **Production-grade DNS management** with DNSSEC and monitoring
- **Redundant connectivity** with multiple interconnect paths
- **Enhanced security controls** and monitoring
- **Comprehensive logging and alerting**

## Files

### `networking.tf`
Production VPC network with enterprise-grade security:
- **Multi-region deployment** (us-central1, us-east1, us-west1)
- **Static NAT IPs** for predictable outbound traffic
- **Enhanced logging** with full flow sampling
- **Restrictive firewall rules** with comprehensive logging
- **Private Google Access** for secure API communication
- **Service networking** for managed services

**Blast Radius: CRITICAL** - Changes affect all production workloads

### `dns.tf`
Production DNS with high availability and security:
- **DNSSEC enabled** for all public zones
- **Health checking** and failover routing
- **Enhanced monitoring** with query logging
- **Security policies** to block malicious domains
- **CAA records** for certificate authority control
- **Email security** (SPF, DKIM, DMARC)

**Blast Radius: HIGH** - DNS issues affect all services

### `peering.tf`
Production network connectivity and peering:
- **Partner network peering** with strict route control
- **HA VPN gateways** for redundant connectivity
- **BGP routing** with custom advertisements
- **Network Connectivity Center** for centralized management
- **Private Service Connect** for secure API access
- **Cross-region load balancing**

**Blast Radius: HIGH** - Connectivity issues affect hybrid workloads

### `interconnect.tf`
Production-grade dedicated connectivity:
- **Redundant dedicated interconnects** across multiple regions
- **Multiple BGP sessions** for high availability
- **BFD (Bidirectional Forwarding Detection)** for fast failover
- **Partner interconnect** for cost-effective connectivity
- **Comprehensive monitoring** and SLA tracking
- **Advanced security** with traffic encryption

**Blast Radius: CRITICAL** - Outages affect on-premises connectivity

### `variables.tf`
Production-specific variables with validation:
- **Strict validation rules** for all inputs
- **Security-focused defaults** 
- **Compliance annotations**
- **Resource scaling parameters**

## Architecture

### Network Topology
```
Production VPC (10.0.0.0/8)
├── us-central1 (10.1.0.0/16)
│   ├── Production Workloads: 10.1.0.0/17
│   ├── GKE Pods: 10.1.128.0/17
│   └── GKE Services: 10.1.64.0/19
├── us-east1 (10.2.0.0/16)
│   ├── Production Workloads: 10.2.0.0/17
│   ├── GKE Pods: 10.2.128.0/17
│   └── GKE Services: 10.2.64.0/19
└── us-west1 (10.3.0.0/16)
    ├── Production Workloads: 10.3.0.0/17
    ├── GKE Pods: 10.3.128.0/17
    └── GKE Services: 10.3.64.0/19
```

### DNS Hierarchy
```
Production Domains
├── example.com (Main Production Domain)
│   ├── www.example.com
│   ├── api.example.com
│   └── cdn.example.com
├── api.prod.example.com (API Gateway)
└── internal.prod.example.com (Private Services)
    ├── database.internal.prod.example.com
    ├── cache.internal.prod.example.com
    └── monitoring.internal.prod.example.com
```

### Connectivity Architecture
```
Production Connectivity
├── Primary Dedicated Interconnect (10G)
│   ├── us-central1 - BGP Session 1
│   └── us-central1 - BGP Session 2
├── Secondary Dedicated Interconnect (10G)
│   ├── us-east1 - BGP Session 1
│   └── us-east1 - BGP Session 2
├── Partner Interconnect (1G)
│   └── us-central1 - Backup Path
└── HA VPN (Backup)
    ├── Tunnel 1 - us-central1
    └── Tunnel 2 - us-central1
```

## Change Management Process

### 1. Planning Phase
- [ ] Create detailed change request with impact assessment
- [ ] Get approval from infrastructure team lead
- [ ] Schedule during approved maintenance window
- [ ] Prepare rollback procedures

### 2. Testing Phase
- [ ] Test changes in staging environment first
- [ ] Validate with non-production interconnect
- [ ] Perform connectivity tests
- [ ] Review monitoring and alerting

### 3. Deployment Phase
- [ ] Deploy during maintenance window
- [ ] Monitor all metrics during deployment
- [ ] Validate connectivity after changes
- [ ] Update documentation

### 4. Validation Phase
- [ ] Confirm all services are operational
- [ ] Check monitoring dashboards
- [ ] Validate external connectivity
- [ ] Document any issues or learnings

## Security Controls

### Network Security
- **Firewall rules** with deny-all default and explicit allows
- **Private Google Access** to avoid external IP requirements
- **VPC Flow Logs** with full sampling for security analysis
- **IAP (Identity-Aware Proxy)** for secure administrative access

### DNS Security
- **DNSSEC** for all public zones
- **Response policies** to block known malicious domains
- **Query logging** for security analysis
- **CAA records** to control certificate issuance

### Connectivity Security
- **IPSec encryption** for all interconnect traffic
- **BGP authentication** and route filtering
- **Private peering** without public IP exposure
- **Monitoring and alerting** for security events

## Monitoring and Alerting

### Critical Alerts
- BGP session down
- Interconnect bandwidth > 80%
- DNS resolution failures
- VPN tunnel down
- Firewall rule violations

### SLA Monitoring
- **Interconnect availability**: 99.9%
- **DNS resolution time**: < 50ms
- **Network latency**: < 10ms regional

### Dashboards
- Network connectivity health
- DNS query performance
- Interconnect utilization
- Security events

## Disaster Recovery

### Network Redundancy
- Multiple interconnect paths
- Multi-region deployment
- Automatic failover routing
- Cross-region backup connectivity

### DNS Resilience
- Multiple name servers
- Health checking with failover
- Regional DNS resolution
- Backup DNS providers

### Recovery Procedures
1. **Primary interconnect failure**: Traffic automatically routes to secondary
2. **Regional outage**: Services fail over to alternate region
3. **DNS failure**: Backup DNS servers handle queries
4. **Complete connectivity loss**: Emergency VPN activation

## Compliance and Governance

### Change Control
- All changes require approval
- Automated testing in staging
- Mandatory rollback procedures
- Post-change validation

### Documentation
- Architecture diagrams maintained
- Runbooks for all procedures
- Incident response playbooks
- Regular architecture reviews

### Audit Trail
- All changes logged and tracked
- Terraform state managed centrally
- Access logs maintained
- Regular compliance audits

## Cost Optimization

### Resource Sizing
- Right-sized interconnect bandwidth
- Efficient NAT IP allocation
- Regional resource placement
- Reserved capacity where applicable

### Monitoring
- Cost alerts for unexpected charges
- Regular cost optimization reviews
- Resource utilization tracking
- Rightsizing recommendations

## Emergency Procedures

### Emergency Contacts
- **Infrastructure Team Lead**: [Contact Info]
- **Network Operations Center**: [Contact Info]
- **Security Operations Center**: [Contact Info]

### Break Glass Procedures
1. For critical production issues
2. Emergency change approval process
3. Rapid response team activation
4. Post-incident review required

### Rollback Procedures
1. Stop current deployment
2. Revert to previous Terraform state
3. Validate connectivity
4. Escalate if rollback fails

## Dependencies

### External Dependencies
- On-premises network infrastructure
- DNS registrar configurations
- Certificate authorities
- Monitoring systems

### Internal Dependencies
- Organization-level policies (`../../org/`)
- Project configurations
- IAM policies and permissions
- Security policies

## Troubleshooting

### Common Issues

#### BGP Session Flapping
- Check interconnect physical layer
- Verify BGP configuration
- Review route advertisements
- Contact carrier if needed

#### DNS Resolution Issues
- Check DNSSEC validation
- Verify DNS policies
- Review query logs
- Test from multiple locations

#### Connectivity Problems
- Validate firewall rules
- Check route tables
- Test with traceroute
- Review VPC flow logs

### Support Resources
- [GCP Network Documentation](https://cloud.google.com/vpc/docs)
- [Cloud DNS Documentation](https://cloud.google.com/dns/docs)
- [Cloud Interconnect Documentation](https://cloud.google.com/network-connectivity/docs/interconnect)
- Internal knowledge base and runbooks

---

**Remember: Production changes require extreme care. When in doubt, escalate to senior team members.**