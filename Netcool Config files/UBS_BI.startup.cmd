##############################################################################
# Netcool/OMNIbus Bi-directional ObjectServer Gateway 7.2
#
# UBS Specific BI gateway startup command definition file.
#
# Revision History:
#	2.0 	28 May 2008	Initial cut By G.Thomas
#
# Notes: Command examples.
#
#	GET CONFIG;
#	SET LOG LEVEL TO debug;
#	TRANSFER FROM 'master.names' TO 'resync.names'
#			VIA FILTER 'Name != \'nobody\''
#			DO NOT DELETE;
#
##############################################################################

#TRANSFER FROM 'security.users' TO 'transfer.users' DO NOT DELETE;
#TRANSFER FROM 'security.groups' TO 'transfer.groups' VIA FILTER 'GroupID > 7' DO NOT DELETE;
#TRANSFER FROM 'security.group_members' TO 'transfer.group_members' DO NOT DELETE;

#TRANSFER FROM 'custom.suppress' TO 'custom.suppress' DELETE;
#TRANSFER FROM 'alerts.colors' TO 'alerts.colors' DO NOT DELETE;
#TRANSFER FROM 'alerts.conversions' TO 'alerts.conversions' DO NOT DELETE;
#TRANSFER FROM 'alerts.col_visuals' TO 'alerts.col_visuals' DO NOT DELETE;
#TRANSFER FROM 'alerts.objclass' TO 'alerts.objclass' DO NOT DELETE;
#TRANSFER FROM 'alerts.objmenus' TO 'alerts.objmenus' DO NOT DELETE;
#TRANSFER FROM 'alerts.objmenuitems' TO 'alerts.objmenuitems' DO NOT DELETE;
#TRANSFER FROM 'alerts.resolutions' TO 'alerts.resolutions' DO NOT DELETE;
#TRANSFER FROM 'tools.actions' TO 'tools.actions' DO NOT DELETE;
#TRANSFER FROM 'tools.action_access' TO 'tools.action_access' DO NOT DELETE;
#TRANSFER FROM 'tools.menus' TO 'tools.menus' DO NOT DELETE;
#TRANSFER FROM 'tools.menu_items' TO 'tools.menu_items' DO NOT DELETE;
#TRANSFER FROM 'tools.menu_defs' TO 'tools.menu_defs' DO NOT DELETE;
#TRANSFER FROM 'tools.prompt_defs' TO 'tools.prompt_defs' DO NOT DELETE;
