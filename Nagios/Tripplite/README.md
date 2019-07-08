## Tripp Lite PDU & UPS Checks for Nagios

These Nagios checks look at a Tripp Lite PDU or UPS and report on:
* Input Source **( PDU Only )**
* Alarms & Device Info **( PDU & UPS )**
* Battery Status, Battery Minutes Remaining, Output Source, Seconds running on Battery **( UPS Only )**

These scripts are based on the 'check_snmp_load' and 'check_snmp_mem' scripts by Patrick Proy.

These scripts are functional, but the code is messy, not from Patrick's coding, by my hacking them apart and back together again.  Some cleanup will be necessary, but they do work! :)

Example configurations:
-----

```
define host {
        use             tripplite_template
        host_name       %device_name%
        alias           TrippLite UPS/PDU
        address         %ip_address%
        hostgroups      adc
        parents         %parent_devices%
        }


define service{
        hostgroup_name                          PDU
        service_description                     Input Source
        check_command                           check_tlats_Source
        use                                     generic-service
}
define service{
        hostgroup_name                          PDU
        service_description                     Alarms
        check_command                           check_tl_alarms
        use                                     generic-service
}
define service{
        hostgroup_name                          PDU
        service_description                     Device Info
        check_command                           check_tl_info
        use                                     generic-service
}
define service{
        hostgroup_name                          UPS
        service_description                     Battery Status
        check_command                           check_tlups_battstatus
        use                                     generic-service
}
define service{
        hostgroup_name                          UPS
        service_description                     Minutes Remaining
        check_command                           check_tlups_minutesremain
        use                                     generic-service
}
define service{
        hostgroup_name                          UPS
        service_description                     Output Source
        check_command                           check_tlups_outputsource
        use                                     generic-service
}
define service{
        hostgroup_name                          UPS
        service_description                     Seconds on Battery
        check_command                           check_tlups_seconbatt
        use                                     generic-service
}


define command{
        command_name    tl_ats_source
        command_line    $USER1$/check_tlats_source.pl -H $HOSTADDRESS$ -C %snmp_community%
}
define command{
        command_name    tl_alarms
        command_line    $USER1$/check_tl_alarms.pl -H $HOSTADDRESS$ -C %snmp_community% -c 1
}
define command{
        command_name    tl_info
        command_line    $USER1$/check_tl_info.pl -H $HOSTADDRESS$ -C %snmp_community%
}
define command{
        command_name    tl_ups_batterystatus
        command_line    $USER1$/check_tlups_battstatus.pl -H $HOSTADDRESS$ -C %snmp_community%
}
define command{
        command_name    tl_ups_minutesremaining
        command_line    $USER1$/check_tlups_minutesremain.pl -H $HOSTADDRESS$ -C %snmp_community% -w 30 -c 20
}
define command{
        command_name    tl_ups_outputsource
        command_line    $USER1$/check_tlups_outputsource.pl -H $HOSTADDRESS$ -C %snmp_community%
}
define command{
        command_name    tl_ups_secondsonbattery
        command_line    $USER1$/check_tlups_seconbatt.pl -H $HOSTADDRESS$ -C %snmp_community% -c 60
}

```
