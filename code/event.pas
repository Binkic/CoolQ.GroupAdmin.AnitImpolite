{
* Type=1001 ��Q����
* ���۱�Ӧ���Ƿ����ã������������ڿ�Q������ִ��һ�Σ���������ִ��Ӧ�ó�ʼ�����롣
* ��Ǳ�Ҫ����������������ش��ڡ���������Ӳ˵������û��ֶ��򿪴��ڣ�
}
Function code_eventStartup:longint;
Begin
	exit(0)
End;

{
* Type=1002 ��Q�˳�
* ���۱�Ӧ���Ƿ����ã������������ڿ�Q�˳�ǰִ��һ�Σ���������ִ�в���رմ��롣
* ������������Ϻ󣬿�Q���ܿ�رգ��벻Ҫ��ͨ���̵߳ȷ�ʽִ���������롣
}
Function code_eventExit:longint;
Begin
	exit(0);
End;

{
* Type=1003 Ӧ���ѱ�����
* ��Ӧ�ñ����ú󣬽��յ����¼���
* �����Q����ʱӦ���ѱ����ã�����_eventStartup(Type=1001,��Q����)�����ú󣬱�����Ҳ��������һ�Ρ�
* ��Ǳ�Ҫ����������������ش��ڡ���������Ӳ˵������û��ֶ��򿪴��ڣ�
}
Function code_eventEnable:longint;
//Var a,b,c:longint;
Var
	tconfig :	TJSONData;
	i		:	longint;
	result:PMYSQL_RES;
	rowbuf:TMYSQL_ROW;
Begin
	
	CQ_i_addLog(CQLOG_DEBUG,'Initiation','Initiating ...');						//��ʼ��ʼ��
	tconfig:=Json_OpenFromFile(CQ_i_getAppDirectory+'config.json');				//��ȡ��������
	Config.GMTTimeZone:=tconfig.GetPath('GMTTimeZone').ASInt64;
	MysqlSetting.host		:=tconfig.GetPath('Mysql.host').ASString;
	MysqlSetting.Port		:=tconfig.GetPath('Mysql.port').ASInt64;
	MysqlSetting.DataBase	:=tconfig.GetPath('Mysql.database').ASString;
	MysqlSetting.user		:=tconfig.GetPath('Mysql.user').ASString;
	MysqlSetting.passwd		:=tconfig.GetPath('Mysql.password').ASString;
	tconfig.Clear;	
	tconfig:=Json_OpenFromFile(CQ_i_getAppDirectory+'SensitiveWords.json');
	L_SensitiveWords.len:=1;													//���дʿ��ȡ
	SetLength(L_SensitiveWords.Cont,1);
	L_SensitiveWords.Cont[0].Chl:=0;
	L_SensitiveWords.Cont[0].S:=0;
	For i:=0 to tconfig.FindPath('SensitiveWords').Count-1 do
	Begin
		//writeln(i+1);
		DictTree_Add(L_SensitiveWords,tconfig.FindPath('SensitiveWords['+IntToStr(i)+']').AsString,0,1)
	End;																		//���дʿ��ȡ���
	tconfig.Clear;
	CQ_i_addLog(CQLOG_DEBUG,'Initiation','Libiary Loaded...');
	
	result:=MysqlQuery('SELECT * FROM `essential_querylog` LIMIT 0, 1');
	if result=nil then begin
		mysql_free_result (result);
		result:=MysqlQuery('CREATE TABLE `essential_querylog` (`id` bigint(20) NOT NULL AUTO_INCREMENT,`time` datetime DEFAULT NULL,`fromgroup` bigint(20) DEFAULT NULL,`fromQQ` bigint(20) DEFAULT NULL,`type` text COLLATE utf8_unicode_ci,`msg` longtext COLLATE utf8_unicode_ci,`award` smallint(6) DEFAULT NULL,`sensitivewords` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,`sensitivewords_score` int(11) DEFAULT NULL,`operator` int(11) DEFAULT NULL,PRIMARY KEY (`id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci');
		mysql_free_result (result);
	end
	else
	begin
		mysql_free_result (result);
	end;
	
	CQ_i_addLog(CQLOG_DEBUG,'Initiation','Initiated');
	exit(0)
End;

{
* Type=1004 Ӧ�ý���ͣ��
* ��Ӧ�ñ�ͣ��ǰ�����յ����¼���
* �����Q����ʱӦ���ѱ�ͣ�ã��򱾺���*����*�����á�
* ���۱�Ӧ���Ƿ����ã���Q�ر�ǰ��������*����*�����á�
}
Function code_eventDisable:longint;
Begin
	//close(log);
	exit(0);
End;

{
* Type=21 ˽����Ϣ
* subType �����ͣ�11/���Ժ��� 1/��������״̬ 2/����Ⱥ 3/����������
}
Function code_eventPrivateMsg(
			subType,sendTime		:longint;
			fromQQ					:int64;
			const msg				:ansistring;
			font					:longint):longint;
Begin
	exit(EVENT_IGNORE);
		//���Ҫ�ظ���Ϣ������ÿ�Q�������ͣ��������� exit(EVENT_BLOCK) - �ضϱ�����Ϣ�����ټ�������  ע�⣺Ӧ�����ȼ�����Ϊ"���"(10000)ʱ������ʹ�ñ�����ֵ
		//������ظ���Ϣ������֮���Ӧ��/�������������� exit(return EVENT_IGNORE) - ���Ա�����Ϣ
End;

{
* Type=2 Ⱥ��Ϣ
}
Function code_eventGroupMsg(
			subType,sendTime		:longint;
			fromgroup,fromQQ		:int64;
			fromAnonymous,Omsg		:ansistring;
			font					:longint):longint;
Begin
	if (fromQQ=80000000) and (fromAnonymous<>'') then begin
		exit(EVENT_IGNORE);
	end;
	
	sendTime:=sendTime+Config.GMTTimeZone;
	Log_Query_Add(sendTime,fromGroup,fromQQ,'chat',Omsg); 	//��¼����
	Log_Anit_Impolite(SendTime,fromGroup,fromQQ);
	
	exit(EVENT_IGNORE);
	//exit(EVENT_BLOCK);
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;

{
* Type=4 ��������Ϣ
}
Function code_eventDiscussMsg(
			subType,sendTime		:longint;
			fromDiscuss,fromQQ		:int64;
			msg						:ansistring;
			font					:longint):longint;
Begin
	exit(EVENT_IGNORE);
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;


{
*Type=11 Ⱥ�ļ��ϴ��¼�
}
Function code_eventGroupUpload(
			subType,sendTime	:longint;
			fromGroup,fromQQ	:int64;
			Pfileinfo			:ansistring):longint;
Begin
	exit(EVENT_IGNORE);
	//exit(EVENT_IGNORE); 
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;

{
* Type=101 Ⱥ�¼�-����Ա�䶯
* subType �����ͣ�1/��ȡ������Ա 2/�����ù���Ա
}
Function code_eventSystem_GroupAdmin(
			subType,sendTime		:longint;
			fromGroup,
			beingOperateQQ			:int64):longint;
Begin
	exit(EVENT_IGNORE); 
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;

{
* Type=102 Ⱥ�¼�-Ⱥ��Ա����
* subType �����ͣ�1/ȺԱ�뿪 2/ȺԱ���� 3/�Լ�(����¼��)����
* fromQQ ������QQ(��subTypeΪ2��3ʱ����)
* beingOperateQQ ������QQ
}
Function code_eventSystem_GroupMemberDecrease(
			subType,sendTime		:longint;
			fromGroup,fromQQ,
			beingOperateQQ			:int64):longint;
Begin
	exit(EVENT_IGNORE); 
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;

{
* Type=103 Ⱥ�¼�-Ⱥ��Ա����
* subType �����ͣ�1/����Ա��ͬ�� 2/����Ա����
* fromQQ ������QQ(������ԱQQ)
* beingOperateQQ ������QQ(����Ⱥ��QQ)
}
Function code_eventSystem_GroupMemberIncrease(
			subType,sendTime		:longint;
			fromGroup,fromQQ,
			beingOperateQQ			:int64):longint;
Begin
	exit(EVENT_IGNORE);
	//exit(EVENT_IGNORE); 
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;


{
* Type=201 �����¼�-���������
}
Function code_eventFriend_Add(
			subType,sendTime		:longint;
			fromQQ					:int64):longint;
Begin
	exit(EVENT_IGNORE); 
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;


{
* Type=301 ����-�������
* msg ����
* responseFlag
		������ʶ(����������)
		����ҾͲ�����ת����string�ˣ�����������Ҳûʲô��
}
Function code_eventRequest_AddFriend(
			subType,sendTime			:longint;
			fromQQ						:int64;
			const msg					:ansistring;
			responseFlag				:Pchar):longint;
Begin
	CQ_setFriendAddRequest(AuthCode, responseFlag,REQUEST_ACCEPT,'');
	exit(EVENT_IGNORE);
	//exit(EVENT_IGNORE); 
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;

{
* Type=302 ����-Ⱥ���
* subType �����ͣ�1/����������Ⱥ 2/�Լ�(����¼��)������Ⱥ
* msg ����
* responseFlag
		������ʶ(����������)
		�����Ҳ������ת����
}
Function code_eventRequest_AddGroup(
			subType,sendTime			:longint;
			fromGroup,fromQQ			:int64;
			msg							:ansistring;
			responseFlag				:Pchar):longint;
Begin
	exit(EVENT_IGNORE); 
	//exit(EVENT_IGNORE); 
	//���ڷ���ֵ˵��, ����code_eventPrivateMsg������
End;