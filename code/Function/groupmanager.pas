function GM_IspermissionGiven(fromgroup,id:int64;permission:string):boolean;
Begin
	exit(GM_GetPermissionStatus(fromgroup,id,permission)=1);
End;

function GM_IspermissionGiven_default(fromgroup,id:int64;permission:string;level:integer):boolean;
Var
	Info : CQ_Type_GroupMember;
Begin
	if GM_GetPermissionStatus(fromgroup,id,permission)=1 then exit(true);
	CQ_i_getGroupMemberInfo(fromgroup,id,info,false);
	if info.permission>=level then exit(true) else exit(false);
End;