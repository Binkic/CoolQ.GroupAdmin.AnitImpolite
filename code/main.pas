{
	Var
		stats : longint 
		
		//���������ﶨ��ȫ�ֱ�����
}
Const
	MysqlDateTimeFormat='yyyy-mm-dd hh:nn:ss';
	
Type
	T_DictTree	= 	record
						len	:	longint;
						cont:	Array Of Record
									Str	:	Ansistring;
									Chl	:	longint;
									S	:	integer;
									Chls:	Array of longint;
								End;
					end;
	T_SensitiveWordsResult =	record
									s:longint;
									c:ansistring;
								end;
	
Var
	MysqlSetting	:	Record
							user,passwd,database,host:ansistring;
							Port:int64;
						end;
	Config			:	Record
							GMTTimeZone:Longint;
						End;
	L_SensitiveWords:	T_DictTree;
{$INCLUDE lib\tools.pas}
{$INCLUDE function\groupmanager.pas}
{$INCLUDE function\log.pas}

{$INCLUDE event.pas}
{$INCLUDE menu.pas}	//����˵�
//�Լ�������Ҫ�����Ĵ����ļ���