# Non-Production Global Infrastructure

This directory contains Terraform configurations for **non-production** global shared infrastructure components including staging, development, and test environments. These resources have **LOWER BLAST RADIUS** and allow for more flexible experimentation.

## 🔧 DEVELOPMENT ENVIRONMENT 🔧

**NON-PRODUCTION ENVIRONMENT - SAFE FOR EXPERIMENTATION**

- Changes can be tested more freely
- Cost-optimized configurations
- Simplified security for development workflows
- Faster iteration and testing cycles
- Integration testing capabilities

## Overview

The non-production global infrastructure provides:
- **Cost-optimized VPC networks** for development and testing
- **Flexible DNS management** for multiple environments
- **Test connectivity** options for validation
- **Development-friendly security** controls
- **Experimental feature support**

## Files

### `networking.tf`
Non-production VPC network optimized for development:
- **Single region deployment** (us-central1) for cost savings
- **Auto-allocated NAT IPs** for cost optimization
- **Reduced logging** to minimize costs
- **Permissive firewall rules** for development flexibility
- **Multiple environments** (staging, dev, test)
- **Shared VPC support** for multi-project scenarios

**Blast Radius: LOW** - Changes only affect development workloads

### `dns.tf`
Flexible DNS configuration for multiple environments:
- **Basic DNSSEC** for testing security features
- **Short TTLs** for rapid iteration
- **Wildcard records** for dynamic environments
- **Feature branch** DNS support
- **PR preview** environments
- **Load testing** endpoints

**Blast Radius: LOW** - DNS issues only affect development/testing

### `peering.tf`
Development-friendly connectivity options:
- **Shared services peering** for common resources
- **Sandbox networks** for isolated testing
- **Cross-project peering** for multi-project scenarios
- **Temporary firewall rules** for testing
- **Experimental configurations**

**Blast Radius: LOW** - Limited to non-production environments

### `interconnect.tf`
Test interconnect configurations for validation:
- **Partner interconnects** for testing hybrid scenarios
- **Development attachments** for feature validation
- **Staging validation** for pre-production testing
- **Experimental configurations** for R&D
- **Load testing** capabilities

**Blast Radius: MINIMAL** - Test connections only

### `variables.tf`
Development-optimized variables:
- **Flexible validation** for testing scenarios
- **Cost-optimization defaults**
- **Development-friendly configurations**
- **Experimental feature flags**

## Architecture

### Network Topology
```
Non-Production VPC (10.50.0.0/8)
├── Staging (10.51.0.0/16)
│   ├── Workloads: 10.51.0.0/17
│   ├── GKE Pods: 10.51.128.0/17
│   └── GKE Services: 10.51.64.0/19
├── Development (10.52.0.0/16)
│   ├── Workloads: 10.52.0.0/17
│   ├── GKE Pods: 10.52.128.0/17
│   └── GKE Services: 10.52.64.0/19
└── Test (10.53.0.0/16)
    ├── Workloads: 10.53.0.0/17
    ├── GKE Pods: 10.53.128.0/17
    └── GKE Services: 10.53.64.0/19
```

### DNS Hierarchy
```
Non-Production Domains
├── dev.example.com (Development)
│   ├── *.dev.example.com (Wildcard)
│   ├── api.dev.example.com
│   └── pr-123.dev.example.com (PR Preview)
├── staging.example.com (Staging)
│   ├── www.staging.example.com
│   └── api.staging.example.com
├── test.example.com (Testing)
│   ├── load-test.test.example.com
│   └── feature-test.test.example.com
└── internal.nonprod.example.com (Private)
    ├── database.dev.internal.nonprod.example.com
    ├── cache.staging.internal.nonprod.example.com
    └── monitoring.internal.nonprod.example.com
```

### Connectivity Architecture
```
Non-Production Connectivity
├── Shared Services Peering
│   └── Common resources and tools
├── Partner Test Interconnect (50M)
│   └── us-central1 - Basic BGP
├── Development Interconnect (100M)
│   └── us-central1 - Feature testing
├── Staging Interconnect (1G)
│   └── us-central1 - Pre-production validation
└── Sandbox Networks
    ├── Isolated testing environment 1
    └── Isolated testing environment 2
```

## Development Workflows

### Feature Development
1. **Feature Branch Environment**
   - Automatic DNS: `feature-name.dev.example.com`
   - Isolated resources
   - Temporary firewall rules
   - Auto-cleanup after merge

2. **PR Preview Environment**
   - DNS: `pr-123.dev.example.com`
   - Review-specific resources
   - Integration testing
   - Auto-cleanup after merge

3. **Staging Validation**
   - Production-like configuration
   - Pre-production testing
   - Performance validation
   - Security testing

### Testing Scenarios

#### Integration Testing
- Cross-environment peering for integration tests
- Shared services access
- Database and cache connections
- Monitoring and logging validation

#### Load Testing
- Dedicated load testing domains
- Performance testing interconnects
- Bandwidth and latency validation
- Stress testing capabilities

#### Security Testing
- Penetration testing environments
- Security policy validation
- DNS security testing
- Network isolation testing

## Change Management Process

### 1. Development Changes
- [ ] Create feature branch
- [ ] Deploy to development environment
- [ ] Test functionality
- [ ] Create pull request

### 2. Staging Validation
- [ ] Deploy to staging environment
- [ ] Run integration tests
- [ ] Performance validation
- [ ] Security testing

### 3. Production Readiness
- [ ] Document changes
- [ ] Create production change request
- [ ] Get production team approval
- [ ] Schedule production deployment

## Security Controls

### Development Security
- **Permissive internal rules** for development flexibility
- **IAP access** for secure remote development
- **Basic logging** for cost optimization
- **Temporary access** capabilities

### Staging Security
- **Production-like security** for validation
- **Enhanced monitoring** for testing
- **Security policy testing**
- **Compliance validation**

### Network Isolation
- **Environment separation** between dev/staging/test
- **Sandbox isolation** for experimental work
- **Temporary network access** with auto-cleanup
- **Cross-environment controls**

## Cost Optimization

### Resource Efficiency
- **Auto-allocated NAT IPs** vs reserved IPs
- **Reduced logging** for cost savings
- **Single region deployment** for most resources
- **Smaller interconnect bandwidths**

### Auto-Cleanup
- **Temporary resource cleanup**
- **Feature branch environment removal**
- **PR preview environment cleanup**
- **Unused resource detection**

### Cost Monitoring
- Budget alerts for unexpected costs
- Resource utilization tracking
- Cost optimization recommendations
- Regular cost reviews

## Monitoring and Alerting

### Development Monitoring
- **Basic connectivity** monitoring
- **Application performance** tracking
- **Error rate** monitoring
- **Development-specific metrics**

### Staging Monitoring
- **Production-like monitoring** for validation
- **Performance testing** metrics
- **Security event** monitoring
- **Integration test** results

### Cost Monitoring
- **Budget alerts** for cost overruns
- **Resource utilization** tracking
- **Optimization recommendations**
- **Trend analysis**

## Environment Management

### Development Environment
- **Rapid deployment** capabilities
- **Feature branch** support
- **Developer-friendly** configurations
- **Minimal restrictions**

### Staging Environment
- **Production validation** capabilities
- **Performance testing** support
- **Security validation**
- **Integration testing**

### Test Environment
- **Load testing** capabilities
- **Security testing** support
- **Experimental features**
- **Isolation testing**

## Experimental Features

### Sandbox Environments
- **Completely isolated** networks
- **Experimental configurations**
- **Research and development**
- **Third-party integrations**

### Temporary Configurations
- **Time-limited resources**
- **Test-specific configurations**
- **Proof-of-concept** deployments
- **Auto-cleanup mechanisms**

### Advanced Testing
- **Chaos engineering**
- **Fault injection**
- **Performance benchmarking**
- **Security penetration testing**

## Integration Testing

### Cross-Environment Testing
- Staging to production connectivity validation
- Service integration testing
- Data flow validation
- Monitoring integration

### Multi-Project Testing
- Cross-project connectivity
- Service mesh validation
- Identity and access testing
- Resource sharing validation

## Troubleshooting

### Common Development Issues

#### DNS Resolution Problems
- Check DNS propagation
- Verify wildcard configurations
- Test from different locations
- Review DNS policies

#### Connectivity Issues
- Validate firewall rules
- Check peering configurations
- Test routing tables
- Review network policies

#### Performance Issues
- Check resource allocation
- Review network bandwidth
- Validate load balancing
- Monitor application metrics

### Support Resources
- Development team documentation
- Internal knowledge base
- GCP documentation links
- Community resources

## Best Practices

### Development Best Practices
1. **Clean up resources** after testing
2. **Use descriptive naming** for easy identification
3. **Document experimental** configurations
4. **Monitor costs** regularly
5. **Follow security guidelines** even in development

### Testing Best Practices
1. **Test in staging** before production
2. **Validate security** configurations
3. **Performance test** under load
4. **Document test results**
5. **Clean up test resources**

### Cost Management Best Practices
1. **Right-size resources** for actual needs
2. **Use auto-cleanup** for temporary resources
3. **Monitor costs** regularly
4. **Optimize for development** workflows
5. **Plan resource usage**

## Migration to Production

### Readiness Checklist
- [ ] Tested in staging environment
- [ ] Performance validated
- [ ] Security reviewed
- [ ] Documentation updated
- [ ] Production team approval
- [ ] Change management approval
- [ ] Rollback plan prepared

### Production Considerations
- [ ] Enhanced security requirements
- [ ] Monitoring and alerting setup
- [ ] Backup and disaster recovery
- [ ] Compliance requirements
- [ ] SLA considerations

---

**Remember: Non-production environments are for learning and validation. Use them to test thoroughly before production deployment.**