Function DictTree_Add(Var Tree : T_DictTree;Str:Ansistring;Pos,P:longint):longint;
//字典树 : 插入一个词语
Var
	i	:	longint;
Begin
	//writeln(UTF8ToAnsi(Str),Pos:8,P:8);
	
	if P>length(Str) then begin
		inc(Tree.Cont[Pos].S);
		exit(0);
	end;

	for i:=0 to Tree.cont[pos].Chl-1 do begin
		//writeln(Str[p],' ',Tree.Cont[Tree.Cont[pos].Chls[i]].Str);
		if Str[p]=Tree.Cont[Tree.Cont[pos].Chls[i]].Str then begin
			DictTree_Add(Tree,Str,Tree.Cont[pos].Chls[i],P+1);
			exit(0);
		end;
	end;
	Inc(Tree.Len);
	SetLength(Tree.Cont,Tree.Len);
	Tree.Cont[Tree.Len-1].Str:=Str[p];
	Tree.Cont[Tree.Len-1].Chl:=0;
	Tree.Cont[Tree.Len-1].S:=0;
	inc(Tree.Cont[Pos].Chl);
	SetLength(Tree.Cont[Pos].Chls,Tree.Cont[Pos].Chl);
	Tree.Cont[Pos].Chls[Tree.Cont[Pos].Chl-1]:=Tree.Len-1;
	DictTree_Add(Tree,Str,Tree.Len-1,P+1);
	
	exit(0);
End;

Function DictTree_Find_Main(Var Tree : T_DictTree;Str:Ansistring;Pos,P:longint;S:ansistring):T_SensitiveWordsResult;
//字典树 : 查找词语 主函数
Var
	i		:	longint;
	Result	:	T_SensitiveWordsResult;
Begin
	//writeln(Str,' ',p,' ',S,' ',Length(s),' ',UTF8ToAnsi(S));
	DictTree_Find_Main.s:=0;
	DictTree_Find_Main.c:='';
	
	if Tree.cont[Pos].S=1 then begin
		//取到某敏感词;
		DictTree_Find_Main.c:=DictTree_Find_Main.c+S+Tree.cont[Pos].Str+' '; //记录这个词
		inc(DictTree_Find_Main.s);
	end;
	
	if  P>Length(Str) then exit; //太长了
	
	for i:=0 to Tree.cont[pos].Chl-1 do begin
		//writeln(Str,' ',p,' ',S,' ',Length(s),' ',UTF8ToAnsi(S),' ',Tree.Cont[Tree.Cont[pos].Chls[i]].Str);
		if Str[p]=Tree.Cont[Tree.Cont[pos].Chls[i]].Str then begin
			Result:=DictTree_Find_Main(Tree,Str,Tree.Cont[pos].Chls[i],P+1,S+Tree.cont[Pos].Str);
			DictTree_Find_Main.s:=DictTree_Find_Main.s+Result.s;
			DictTree_Find_Main.c:=DictTree_Find_Main.c+Result.c;
			exit();	
		end;
	end;
End;

Function DictTree_Find(Var Tree : T_DictTree; Str:Ansistring):T_SensitiveWordsResult;
//字典树 : 查找词语 调用函数
Var
	i		:	longint;
	Result	:	T_SensitiveWordsResult;
Begin
	DictTree_Find.s:=0;
	DictTree_Find.c:='';
	for i := 1 to length(Str) do Begin
		//writeln;
		//writeln(i);
		Result:=DictTree_Find_Main(Tree,Str,0,i,'');
		DictTree_Find.s:=DictTree_Find.s+Result.s;
		DictTree_Find.c:=DictTree_Find.c+Result.c;
		//writeln('------------------------');
	End;
End;

Function Log_MsgFilter(str:ansistring):ansistring;
//清理掉酷Q码 防止误识别
Var
	i	:	longint;
	b	:	boolean;
Begin
	Log_MsgFilter:='';
	b:=true;
	
	for i:=1 to length(str) do begin
		if str[i]='[' then b:=false
		else if str[i]=']' then b:=true;
		
		if b then Log_MsgFilter:=Log_MsgFilter+str[i];
	end;
	
	CQ_CharDecode(Log_MsgFilter);
End;

Function Log_Query_Add(SendTime,fromgroup,fromQQ:int64;qtype:ansistring;Var msg:ansistring):longint;
//把本条消息记录入库
Var
	query	:	ansistring;
	result	:	PMYSQL_RES;
	SW		:	T_SensitiveWordsResult;				//字典树优化敏感词查找以提高运行速度
Begin
	SW:=DictTree_Find(L_SensitiveWords,AnsiToUTF8(Log_MsgFilter(msg)));
	if SW.c='' then SW.c:='NULL' else SW.c:='"'+strencode(UTF8ToAnsi(SW.c))+'"';
	query:='INSERT INTO essential_querylog (`time`,`fromgroup`,`fromQQ`,`type`,`msg`,`sensitivewords`,`sensitivewords_score`) VALUES ("%s","%s","%s","%s","%s",%s,%s)';
	query:=format(query,
			[
				FormatDateTime('yyyy-mm-dd hh:nn:ss',UnixToDateTime(SendTime)),
				NumToChar(fromgroup),
				NumToChar(fromQQ),
				strencode(qtype),
				strencode(msg),
				SW.c,
				String_Choose(SW.s=0,'NULL','"'+NumToChar(SW.s)+'"')
			]
		);	
	result:=mysqlquery(StoP(query));
	mysql_free_result(result);	
	exit(0);
End;

Function Log_ScoreCalc(T:string;msg:Ansistring):Real;
//消息分数计算
Var
	i		:	longint;
Begin
	if T='chat' then Log_ScoreCalc:=0.5 else Log_ScoreCalc:=1;
	
	if copy(msg,1,8)='[CQ:rich' then Begin     //[CQ:Rich
		{本段代码包含酷Q内测功能，不予以公开}
	End;
	
	i:=1;
	while i<=length(msg) do begin
		if (msg[i]=CR) or (msg[i]=LF) then Log_ScoreCalc:=Log_ScoreCalc+0.1;				//换行判断
		if copy(msg,i,9)='[CQ:image' then begin												//图片判断
			Log_ScoreCalc:=Log_ScoreCalc+0.2;
			i:=i+8;
		end;
		inc(i);
	end;
End;

Function Log_Anit_Impolite(SendTime,FromGroup,FromQQ:int64):longint;
{
!!!!!!!!这里是刷屏和敏感词判断的主要部分，请仔细阅读说明：

实现思路：
	每一次发言都会有一次积分，这一次积分包括了敏感词和其他相关内容（如发言频率）
	在某段时间内获得一定分数则触发禁言。

本函数的注释相对较多

}
Var
	query:ansistring;											//Mysql命令
	result:PMYSQL_RES;											//Mysql查询结果
	rowbuf:TMYSQL_ROW;											//Mysql查询结果 行
	QueryLog:record												//用于储存Mysql的查询结果 也就是聊天记录
				A:array of record									// 聊天记录
							id					:int64;					// 记录编号
							time				:int64;                 // 时间 Unix时间戳
							fromGroup			:int64;                 // 发言所在群
							fromQQ				:int64;                 // 发言QQ
							qtype				:string;                // 发言类型 本版本为阉割版Demo，故皆为 ’chat‘
							msg					:ansistring;            // 发言记录
							award				:integer;               // 与签到记录挂钩，签到功能在本版本中被阉割了
							sensitivewords		:ansistring;            // 本消息触犯的敏感词
							sensitivewords_score:longint;               // 敏感词积分
							operate				:longint;               // 操作 暂时无用
							                                            // 
							score				:Real;                  // 本消息的积分
						end;
				N:longint;											// A 的 数组长度
			end;
	i   	:longint;
	score	:real;
Begin

	If GM_IspermissionGiven_default(fromgroup,fromQQ,'essential.log.anitimpolite.passby',2) then exit(0);
	//如果用户被赋予了 "essential.log.anitimpolite.passby" 或该群员是群管理 则跳过筛查

	query:='SELECT * FROM `essential_querylog` WHERE `fromQQ`="%FROMQQ%" AND `time`>="%TIME%" ORDER BY `time`, `id`';
	Message_Replace(query,'%TIME%',FormatDateTime(MysqlDateTimeFormat,UnixToDateTime(SendTime-5)));				//最近五秒的聊天记录
	Message_Replace(query,'%FROMQQ%',NumToChar(fromQQ));
	
	result:=MysqlQuery(StoP(query));			//查询记录
	rowbuf:=mysql_fetch_row(result);			//第一条
	
	if rowbuf=nil then begin
		mysql_free_result(result);				//防止程序出毛病，预留一个无结果出口
		exit(0);
	end;
	
	QueryLog.N:=0;								//读取聊天记录
	repeat
		inc(QueryLog.N);						//数组长度+1
		setlength(QueryLog.A,QueryLog.N);
		
		QueryLog.A[QueryLog.N-1].id						:=CharToNum(PtoS(rowbuf[0]));
		QueryLog.A[QueryLog.N-1].time					:=DateTimeToUnix(MysqlDateTimeDecode(PtoS(rowbuf[1])));
		QueryLog.A[QueryLog.N-1].fromGroup				:=CharToNum(PtoS(rowbuf[2]));
		QueryLog.A[QueryLog.N-1].fromQQ					:=CharToNum(PtoS(rowbuf[3]));
		QueryLog.A[QueryLog.N-1].qtype					:=StrDecode(PtoS(rowbuf[4]));
		QueryLog.A[QueryLog.N-1].msg					:=StrDecode(PtoS(rowbuf[5]));
		QueryLog.A[QueryLog.N-1].award					:=CharToNum(PtoS(rowbuf[6]));
		QueryLog.A[QueryLog.N-1].sensitivewords			:=StrDecode(PtoS(rowbuf[7]));
		QueryLog.A[QueryLog.N-1].sensitivewords_score	:=CharToNum(PtoS(rowbuf[8]));
		QueryLog.A[QueryLog.N-1].operate				:=CharToNum(PtoS(rowbuf[9]));
		
		rowbuf:=mysql_fetch_row(result);
	until rowbuf=nil;
	mysql_free_result(result);					//聊天记录读取完毕
	
	QueryLog.A[0].Score:=Log_ScoreCalc(QueryLog.A[0].QType,QueryLog.A[0].Msg)+QueryLog.A[0].sensitivewords_score*0.5;
	for i:=1 to QueryLog.N-1 do begin
		QueryLog.A[i].Score:=
			Max(0,1-abs(QueryLog.A[i].Time-QueryLog.A[i-1].Time))+				//发言频率 在同一秒内的发言则积分加一
			Log_ScoreCalc(QueryLog.A[i].QType,QueryLog.A[i].Msg)+				//特殊积分 看上面的函数
			QueryLog.A[i].sensitivewords_score*0.5;								//敏感词积分
	end;
	
	Score:=0;
	for i:=QueryLog.N-1 Downto 0 do begin
			if QueryLog.A[i].fromGroup=fromGroup
				then Score:=Score+QueryLog.A[i].Score
				else Score:=Score+QueryLog.A[i].Score*0.5;						//非本群积分则给他个五折，防止出事
			CQ_i_addLog(CQLOG_DEBUG,'Log_Anit_Impolite',Format('%s %s %s',[QueryLog.A[i].Msg,RealToDisplay(Score,8),RealToDisplay(QueryLog.A[i].Score,8)]));	
			//把本次的筛查结果输出到酷Qlog
	end;
	if (SendTime-QueryLog.A[i].time<=5) and (Score>5) then begin
		CQ_i_setGroupMute(FromGroup,FromQQ,600);
		//满足在这五秒内得到5分则禁言
	end;
	CQ_i_addLog(CQLOG_DEBUG,'Log_Anit_Impolite',RealToDisplay(Score,8));
	//输出总筛查结果到酷Qlog
	exit(0);
End;