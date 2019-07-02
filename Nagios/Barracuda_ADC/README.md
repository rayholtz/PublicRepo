## Barracuda ADC Checks for Nagios

These Nagios checks look at a Barracuda ADC and report on the Load, Storage, and Cluster Status.  
They are based on the 'check_snmp_load' and 'check_snmp_mem' scripts by Patrick Proy


Example configurations:
======

define host {
        use             barracuda_template
        host_name       %adc_name%
        alias           Barracuda ADC 340
        address         %ip_address%
        hostgroups      adc
        parents         %parent_devices%
        }

define service{
        hostgroup_name                          adc
        service_description                     CPU Load
        check_command                           check_adc_load
        use                                     generic-service
}
define service{
        hostgroup_name                          adc
        service_description                     Storage Use
        check_command                           check_adc_storage
        use                                     generic-service
}
define service{
        hosts                                   %adc_name%
        service_description                     Cluster status
        check_command                           check_adc_cluster!%node_role%
\# For the check command line, enter the node role for that device, either 'Primary' or 'Backup'.
        use                                     generic-service
}


define command {
       command_name     check_adc_load
       command_line     $USER1$/check_adc_load.pl -H $HOSTADDRESS$ -w 50 -c 70 -C %snmp_community%
}
define command {
       command_name     check_adc_storage
       command_line     $USER1$/check_adc_storage.pl -H $HOSTADDRESS$ -w 50 -c 70 -C %snmp_community%
}
define command {
       command_name     check_adc_cluster
       command_line     $USER1$/check_adc_cluster.pl -H $HOSTADDRESS$ -C %snmp_community% -c $ARG1$
}

