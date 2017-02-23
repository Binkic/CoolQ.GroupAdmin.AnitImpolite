{
**************************************
        某奇怪的中文字符支持
**************************************
}

Function RegExEncode(s:ansistring):ansistring;
Begin
	Message_Replace(s,'\','\\');
	Message_Replace(s,'*','\*');
	Message_Replace(s,'.','\.');
	Message_Replace(s,'?','\?');
	Message_Replace(s,'+','\+');
	Message_Replace(s,'$','\$');
	Message_Replace(s,'^','\^');
	Message_Replace(s,'[','\[');
	Message_Replace(s,']','\]');
	Message_Replace(s,'(','\(');
	Message_Replace(s,')','\)');
	Message_Replace(s,'{','\{');
	Message_Replace(s,'}','\}');
	Message_Replace(s,'|','\|');
	Message_Replace(s,'/','\/');
	Message_Replace(s,CR,'\r');
	Message_Replace(s,LF,'\n');
	exit(s);
End;

Function RegExDecode(s:ansistring):ansistring;
Begin
	Message_Replace(s,'\*','*');
	Message_Replace(s,'\.','.');
	Message_Replace(s,'\?','?');
	Message_Replace(s,'\+','+');
	Message_Replace(s,'\$','$');
	Message_Replace(s,'\^','^');
	Message_Replace(s,'\[','[');
	Message_Replace(s,'\]',']');
	Message_Replace(s,'\(','(');
	Message_Replace(s,'\)',')');
	Message_Replace(s,'\{','{');
	Message_Replace(s,'\}','}');
	Message_Replace(s,'\|','|');
	Message_Replace(s,'\/','/');
	Message_Replace(s,'\r',CR);
	Message_Replace(s,'\n',LF);
	Message_Replace(s,'\\','\');
	exit(s);
End;

Function StrEncode(s:ansistring):ansistring;
//编码
Var
	a:ansistring;
	i:longint;
Begin
	a:='';
	for i:=1 to length(s) do
		if      (s[i]<>'"') and (s[i]<>'''')
			and (s[i]<>'/') and (s[i]<>'\')
			and (s[i]<>'[') and (s[i]<>']')
			and (s[i]<>',') then a:=a+s[i]
		else a:=a+'/'+SDECtoHEX(integer(s[i])div 16)+SDECtoHEX(integer(s[i])mod 16);
	exit(a);
End;

Function StrDecode(s:ansistring):ansistring;
//解码
Var
	i:longint;
	outs:ansistring;
Begin
	outs:='';
	i:=1;
	while i<=length(s) do begin
		if s[i]='/' then begin
			//需要转义
			outs:=outs+GB2312ASCtoChar(s[i+1],s[i+2]);
			i:=i+3;
		end
		else
		begin
			//不需要转义
			outs:=outs+s[i];
			i:=i+1;
		end;
	end;
        exit(outs);
End;

{
**************************************
            Mysql 支持
**************************************
}
Function MysqlQuery(Query:pChar):PMYSQL_RES;
Stdcall;
var
  sock : PMYSQL;
  qmysql : TMYSQL;
  recbuf : PMYSQL_RES;
begin
	  //Write ('Connecting to MySQL...');
	  mysql_init(PMySQL(@qmysql));
	  sock :=  mysql_real_connect(PMysql(@qmysql),StoP(MysqlSetting.Host),StoP(MysqlSetting.User),StoP(MysqlSetting.passwd),nil,MysqlSetting.Port,nil,0);
	  
	  {sock :=  mysql_real_connect(PMysql(@qmysql),				
								StoP(MysqlSetting.Host),
								StoP(MysqlSetting.User),	
								StoP(MysqlSetting.passwd),nil,	
								MysqlSetting.Port,nil,0);	}
	  
	  if sock=Nil then
		begin
		//    Writeln (stderr,'Couldn''t connect to MySQL.');
		//    Writeln (stderr,mysql_error(@qmysql));
		//    halt(1);
		
			CQ_i_setFatal('Couldn''t connect to MySQL'+CRLF+mysql_error(@qmysql));
		
			  mysql_close(sock);
			  exit(nil);
		end;

	//  Writeln ('Done.');
	//  Writeln ('Connection data:');
	//大括号$ifdef Unix反大括号
	//  writeln ('Mysql_port      : ',mysql_port);
	//  writeln ('Mysql_unix_port : ',mysql_unix_port);
	//大括号$endif反大括号
	//  writeln ('Host info       : ',mysql_get_host_info(sock));
	//  writeln ('Server info     : ',mysql_stat(sock));
	//  writeln ('Client info     : ',mysql_get_client_info);
	//
	//  Writeln ('Selecting Database ',DataBase,'...');


	  if mysql_select_db(sock,StoP(MysqlSetting.DataBase)) < 0 then
		begin
		//    Writeln (stderr,'Couldn''t select database ',Database);
		//    Writeln (stderr,mysql_error(sock));
		//    halt (1);
				CQ_i_setFatal('Couldn''t select database '+MysqlSetting.Database+CRLF+mysql_error(sock));
			  mysql_close(sock);
			  exit(nil);
		end;

	//  writeln ('Executing query : ',Query,'...');
	mysql_query(sock,'SET NAMES GBK');
	
		if (mysql_query(sock,Query) < 0) then
		  begin
		//      Writeln (stderr,'Query failed ');
		//      writeln (stderr,mysql_error(sock));
		//      Halt(1);
				CQ_i_setFatal('Query failed'+CRLF+mysql_error(sock));
				mysql_close(sock);
				exit(nil);
		  end;

	  recbuf := mysql_store_result(sock);
	  if RecBuf=Nil then
		begin
		//    Writeln ('Query returned nil result.');
		//    halt (1);
			mysql_close(sock);
			exit(nil);
		end;
	//  Writeln ('Number of records returned  : ',mysql_num_rows (recbuf));
	//  Writeln ('Number of fields per record : ',mysql_num_fields(recbuf));

	  //rowbuf := mysql_fetch_row(recbuf);
	  MysqlQuery:=recbuf;
  
	  //Writeln ('Freeing memory occupied by result set...');
	  mysql_free_result (recbuf);

	  //Writeln ('Closing connection with MySQL.');
	  mysql_close(sock);
end;

{
**************************************
             时间 支持
**************************************
}
Function Time_Unix_Now:int64;
Begin
	exit(DateTimeToUnix(NOW()));
End;

//一些常用工具

Function Json_OpenFromFile(N:ansistring):TJsonData;
Var
	F:TFileStream;
	P:TJSONParser;
Begin	
	F:=TFileStream.create(N,fmopenRead);
	P:=TJSONParser.Create(F);
	Json_OpenFromFile:=P.Parse;
	FreeAndNil(P);
	F.Destroy;
End;

//解析Mysql的时间格式
Function MysqlDateTimeDecode(s:String):TDateTime;
Var
	aYear,aMonth,aDay,aHour,aMinute,aSecond	:	Word;
	//yyyy-mm-dd hh:nn:ss
Begin

	if length(s)<>length(MysqlDateTimeFormat) then exit(EncodeDateTime(1970,1,1,0,0,0,0));

	Val(Copy(s,1,4),aYear);
	Val(Copy(s,6,2),aMonth);
	Val(Copy(s,9,2),aDay);
	Val(Copy(s,12,2),aHour);
	Val(Copy(s,15,2),aMinute);
	Val(Copy(s,18,2),aSecond);

	if not TryEncodeDateTime(aYear,aMonth,aDay,aHour,aMinute,aSecond,0,MysqlDateTimeDecode) then
		exit(EncodeDateTime(1970,1,1,0,0,0,0));
End;