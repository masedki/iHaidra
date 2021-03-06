#include<Trade\Trade.mqh>
CTrade trade ;


input int Port = 2424;
input string Ip ="localhost";
input int refClient = 1;
input int digit=100000;
int port_=0;
int socket = INVALID_HANDLE; 

double iASK =0;
double iBID =0;
double iSpred =0; 
string iLogin ="0";
string iMagic ="0";
string iTimeFrame ="";
string iSymbol ="";
int    iDigits =0;

int iLoop = 0; 


int OnInit()
  {         
            port_ = int ( StringToInteger( IntegerToString(Port)+IntegerToString(refClient) ) );
            long   login=AccountInfoInteger(ACCOUNT_LOGIN);
            iLogin = IntegerToString(login);
            iSymbol = _Symbol ;
            iDigits = int (SymbolInfoInteger(_Symbol,SYMBOL_DIGITS)); 
           
    EventSetMillisecondTimer(20);
    return(INIT_SUCCEEDED);
  
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
      
     EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+






































void OnTimer() {
                     iLoop++;

socket=SocketCreate();
if(socket!=INVALID_HANDLE) {
if(SocketConnect(socket,Ip,Port,20)) {
//***************************************************************************************************************     
   
               double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),iDigits); // Get the Ask Price
               double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),iDigits); // Get the Bid Price
            iTimeFrame = EnumToString((ENUM_TIMEFRAMES)Period());
            string messageSend ="@1"+iLogin+"@2"+iTimeFrame+"@3"+iSymbol+"@4";
                   messageSend+=IntegerToString(iLoop)+"@5"+IntegerToString(iDigits)+"@6";// Add iLoop
                   messageSend+=DoubleToString(Ask)+"@7"+DoubleToString(Bid)+"@8";
            string received = socksend(socket, messageSend) ? socketreceive(socket, 20 ) : ""; 
             if(received!=""){
                     receivedRespons(received); 
                     
                     }    
            
//***************************************************************************************************************              
}
   
else{if(fmod(iLoop,400)==0) Print("Connection ",Ip,":",Port," error ",GetLastError()); }
SocketClose(socket); }
else Print("Socket creation error ",GetLastError()); 
}
//+------------------------------------------------------------------+





void receivedRespons(string res){
    string type = StringSubstr(res,0,2) ;
    if(type=="@_") //5 messages will be received until the order is activated
   {
         string ms1 =  StringSubstr(res,StringFind(res,"@B1"),
         
         StringFind(res,"@E1")+1);
         string log1 = StringSubstr(ms1,StringFind(ms1,"@1")+2,StringFind(ms1,"@2")-5);
         string ms2 =  StringSubstr(res,StringFind(res,"@B2"),StringFind(res,"@E2")) ;
         string log2 = StringSubstr(ms2,StringFind(ms2,"@1")+2,StringFind(ms2,"@2")-5);
         //Print("Message 1 : ",ms1); Print(" Login 1  :",log1);Print("Message 2 : ",ms2);Print(" Login 2  :",log2);
         string  msg = "NULL";
         if(log1==iLogin) msg = ms1;
         if(log2==iLogin) msg = ms2;
         
         
             if(msg!="NULL"){
                        string BuySell = StringSubstr(msg,StringFind(msg,"@2"),StringFind(msg,"@3")) ;
                               BuySell = StringSubstr(BuySell,2,StringFind(BuySell,"@3")-2  ) ;
                        string sym = StringSubstr(msg,StringFind(msg,"@3"),StringFind(msg,"@4")) ;
                               sym = StringSubstr(sym,2,StringFind(sym,"@4")-2  ) ;
                        string lot = StringSubstr(msg,StringFind(msg,"@4"),StringFind(msg,"@5")) ;
                               lot = StringSubstr(lot,2,StringFind(lot,"@5")-2  ) ; 
                        string com = StringSubstr(msg,StringFind(msg,"@5"),StringFind(msg,"@6")) ;
                               com = StringSubstr(com,2,StringFind(com,"@6")-2  ) ;             
                               
                        
                        if(BuySell=="buy" && isOpen(com,sym)==0){
                              trade.Buy(double(lot),NULL,0,0,0,com);
                              Print(" Open Buy ");
                        }
                        if(BuySell=="sell" && isOpen(com,sym)==0){
                              trade.Sell(double(lot),NULL,0,0,0,com);
                              Print(" Open Sell");
                        }
                        if(BuySell=="close"){
                           
                           Close(com,sym);
                           Print(" Close ");
                        
                        }
               }  
   
   }

}




void Close(string com,string sym){
   
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==sym)
           {
           
               if(PositionGetString(POSITION_COMMENT)==com){
                
                          trade.PositionClose(ticket);
                               

                         }
                   
                   }
                   
           
           }
        }
     
}


double isOpen(string com,string sym)
  {
   int pft=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==sym)
           {   
               // pft+=PositionGetDouble(POSITION_PROFIT);
               if(PositionGetString(POSITION_COMMENT)==com){
                     pft++;
               }
               
           }
        }
     }
   return(pft);
  }


















































bool socksend(int sock,string request) 
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0) return(false);
   return(SocketSend(sock,req,len)==len); 
  }



string socketreceive(int sock,int timeout)
  {
   char rsp[];
   string result="";
   uint len;
   uint timeout_check=GetTickCount()+timeout;
   do
     {
      len=SocketIsReadable(sock);
      if(len)
        {
         int rsp_len;
         rsp_len=SocketRead(sock,rsp,len,timeout);
         if(rsp_len>0) 
           {
            result+=CharArrayToString(rsp,0,rsp_len); 
           }
        }
     }
   while((GetTickCount()<timeout_check) && !IsStopped());
   return result;
  }

 



//**************************************************************************************************
//**************************************************************************************************
//**************************************************************************************************
//**************************************************************************************************
 







































void CloseAll()

{   //StringFind

   for (int i=PositionsTotal()-1;i>=0; i--) 
   { 
      {                 
         if(!trade.PositionClose(PositionGetSymbol(i)))   {Print(PositionGetSymbol(i), "PositionClose() method failed. Return code=",trade.ResultRetcode(), ". Code description: ",trade.ResultRetcodeDescription());
         } else  { Print(PositionGetSymbol(i), "PositionClose() method executed successfully. Return code=",trade.ResultRetcode(),    " (",trade.ResultRetcodeDescription(),")"); }
      }
   }
}  



double TotalProfit(int magic)
  {
   double pft=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0)
        {
         if(PositionGetString(POSITION_SYMBOL)==Symbol())
           {
            pft+=PositionGetDouble(POSITION_PROFIT);
           }
        }
     }
   return(pft);
  }