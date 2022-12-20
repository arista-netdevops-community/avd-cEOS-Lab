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
management security
   ssl profile eAPI
      cipher-list HIGH:!eNULL:!aNULL:!MD5:!ADH:!ANULL
      certificate eAPI.crt key eAPI.key
!
management api http-commands
   protocol https ssl profile eAPI
   no shutdown
   !
   vrf MGMT
      no shutdown
!
end