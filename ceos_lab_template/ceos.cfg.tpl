hostname {{ .ShortName }}
username admin privilege 15 secret admin
!
service routing protocols model multi-agent
!
vrf instance MGMT
!
interface Management0
   description oob_management
   vrf MGMT
{{ if .MgmtIPv4Address }}   ip address {{ .MgmtIPv4Address }}/{{ .MgmtIPv4PrefixLength }}{{end}}
{{ if .MgmtIPv6Address }}   ipv6 address {{ .MgmtIPv6Address }}/{{ .MgmtIPv6PrefixLength }}{{end}}
!
management api gnmi
   transport grpc default
      vrf MGMT
!
management api netconf
   transport ssh default
      vrf MGMT
!
management api http-commands
   protocol https
   no shutdown
   !
   vrf MGMT
      no shutdown
!
end