//+---------------------------------------------------------------------------------+
//|                                                         calc.mq4                |
//|                                Copyright © 2009, Borys Chekmasov                |
//|                                     http://uatrader.blogspot.com                |
//|                                     version 3.0       2009.02.09                |
//+---------------------------------------------------------------------------------+
/* Индикатор предназначен для расчета ордеров.
   Действует таким образом: создает на графике 3 линии с именами OPEN, STOP, PROFIT;
   Вы располагаете линии соответственно на уровнях на которых планируете выставить
   ордер(OPEN), установливать стоп (STOP) и тэйк-профит (PROFIT). В свойствах 
   индикатора задайте размер лота, которым планируете открываться (calc_lots) и 
   размер комиссии (comission)для фьючерсов и CFD, если индикатор прикреплен к этим
   инструментам (для фьючерсов комиссия в долларах за лот, для CFD на акции в 
   процентах). После этого просто перетягивая линии Вы увидите в левом верхнем углу
   значение (в долларах) прибыли, убытка по стопу, значение минимальной маржи для 
   открытия позиции и индикатор начертит на графике линию при достижении которой 
   произойдет стопаут.
   Для инструментов в которых пpофит рассчитывается в евро или фунтах (FDAX, FTSE), 
   нужно чтобы в окне обзора символов были отображены форексные пары EURUSD или 
   соответственно GPBUSD, тогда курс будет браться автоматически из соответствующих 
   форексных пар. Аналогично для кроссов XXXYYY должны быть открыты соответствующие 
   основные пары USDYYY или XXXUSD (например для GPBJPY в окне обзора рынка должна 
   быть открыта USDJPY). 
   Для рассчета новых значений достаточно будет перетянуть линии на графике.
   Обновление значений происходит на каждом новом тике, поэтому на низколиквидных
   инструментах или в перерывах между сессиями нажмимайте правой кнопкой на
   графике и выбирайте пункт "обновление" чтоб получить новые значения.            */
//+---------------------------------------------------------------------------------+
#property copyright "Copyright © 2009, Borys Chekmasov"
#property link      "http://uatrader.blogspot.com"

#property indicator_chart_window
 
extern double calc_lots = 0.1; //кол-во лотов
extern double comission = 10; //комиссия

double eurusd_k = 1.3015; //значение курса EURUSD если символ все же отключен в обзоре рынка
double gpbusd_k = 1.4900; //значение курса GPBUSD если символ все же отключен в обзоре рынка
double usdjpy_k = 0.01094;//значение курса 1/USDJPY если символ все же отключен в обзоре рынка

double stopout_level; //уровень стопаута
double proff, preproff, preloss, kurs;
double loss, start_margin, calc_margin,stopout_lvl2, stopout_lvl, marginsum, marginsum2, stopout_lvl3,stopout_lvl4;
double tikk_v;//стоимость тика
double tikk_s;//размер тика
double tikk_m;//режим расчета профита
double tikk_l;//стоимость лота

string comnts;

int leverage_lev;//плечо
// инициализация
int init()
  {

  tikk_v = MarketInfo (Symbol(),MODE_TICKVALUE);
  tikk_s = MarketInfo (Symbol(),MODE_TICKSIZE);
  tikk_m = MarketInfo (Symbol(),MODE_PROFITCALCMODE);
  tikk_l = MarketInfo (Symbol(),MODE_LOTSIZE);
  
  stopout_level = AccountStopoutLevel();
  leverage_lev = AccountLeverage();
  start_margin = calc_lots*MarketInfo(Symbol(), MODE_MARGINREQUIRED);
  calc_margin = calc_lots*MarketInfo(Symbol(), MODE_MARGINMAINTENANCE);
  if ( calc_margin <= 0) 
  {
  calc_margin=calc_lots*tikk_l/leverage_lev;
  }
  comnts = " ";
   if (MarketInfo("EURUSD",MODE_BID)>0) eurusd_k = MarketInfo("EURUSD",MODE_BID);
   if (MarketInfo("GPBUSD",MODE_BID)>0) gpbusd_k = MarketInfo("GPBUSD",MODE_BID);
   if (MarketInfo("USDJPY",MODE_BID)>0) usdjpy_k = 1/MarketInfo("USDJPY",MODE_BID);
  // инструменты со стоимостью пункта в отличных от доллара валютах (Broco):
   kurs = 1;

   // Создание линий для вычислений
   if (ObjectFind("OPEN")== -1) ObjectCreate("OPEN",OBJ_HLINE,0,0,Open[0]);
   if (ObjectFind("STOP")== -1) ObjectCreate("STOP",OBJ_HLINE,0,0,Open[3]);
   if (ObjectFind("PROFIT")== -1) ObjectCreate("PROFIT",OBJ_HLINE,0,0,Open[9]); 
    
 return (0);
     }
 void deinit()
  {
Comment(" ");
//ObjectDelete("STOPOUT");
  }
      
//основной цикл                              
int start()
  {
 
 //вычисление значений калькулятора
   preproff = kurs*MathAbs(ObjectGet("OPEN", OBJPROP_PRICE1)-ObjectGet("PROFIT", OBJPROP_PRICE1));
   preloss = kurs*MathAbs(ObjectGet("OPEN", OBJPROP_PRICE1)-ObjectGet("STOP", OBJPROP_PRICE1));
 marginsum = ((100-stopout_level)/100)*MathAbs(AccountBalance()-calc_margin);
 switch (tikk_m)
 {
 case 0: // Forex
 if (StringSubstr(Symbol(), 3, 3)=="USD") //пары XXXUSD
 {
   proff = preproff*calc_lots*tikk_l;
   loss = preloss*calc_lots*tikk_l;
   if (start_margin<=0)start_margin = calc_lots*tikk_l/leverage_lev;
   if (marginsum<=0)  marginsum = ((100-stopout_level)/100)*MathAbs(AccountBalance()-start_margin);
   stopout_lvl = ObjectGet("OPEN", OBJPROP_PRICE1) + marginsum/(calc_lots*tikk_l);
  stopout_lvl2 = ObjectGet("OPEN", OBJPROP_PRICE1) - marginsum/(calc_lots*tikk_l);

 }
 if (StringSubstr(Symbol(), 0, 3)=="USD") // пары USDXXX
 {
 proff = preproff*calc_lots*tikk_l/ObjectGet("PROFIT", OBJPROP_PRICE1);
 loss = preloss*calc_lots*tikk_l/ObjectGet("STOP", OBJPROP_PRICE1);
 marginsum = ((100-stopout_level)/100)*MathAbs(AccountBalance()-calc_margin/Bid);
 marginsum2 = ((100-stopout_level)/100)*MathAbs(AccountBalance()-calc_margin/Bid);
   stopout_lvl = ObjectGet("OPEN", OBJPROP_PRICE1) + marginsum/(calc_lots*tikk_l/Bid);
   stopout_lvl2 = ObjectGet("OPEN", OBJPROP_PRICE1) - marginsum/(calc_lots*tikk_l/Bid);
 
  if (start_margin==0)start_margin = (calc_margin)/Bid;
 }
 
 if (StringFind(Symbol(), "USD", 0) == -1) // кроскурсы
 {
 if (MarketInfo("USD"+StringSubstr(Symbol(), 3, 3),MODE_BID)>0)
 {
 double tmpinfo = MarketInfo("USD"+StringSubstr(Symbol(), 3, 3),MODE_BID);
 marginsum = ((100-stopout_level)/100)*MathAbs(AccountBalance()-calc_margin/tmpinfo);
 
 proff = preproff*calc_lots*tikk_l/tmpinfo ;
  loss = preloss*calc_lots*tikk_l/tmpinfo ;
   stopout_lvl = ObjectGet("OPEN", OBJPROP_PRICE1) + marginsum/(calc_lots*tikk_l/tmpinfo);
  stopout_lvl2 = ObjectGet("OPEN", OBJPROP_PRICE1) - marginsum/(calc_lots*tikk_l/tmpinfo);
  if (start_margin<=0)start_margin = (calc_lots*tikk_l/leverage_lev)/tmpinfo;
 }
  else 
 {
 if (MarketInfo(StringSubstr(Symbol(), 0, 3)+"USD",MODE_BID)>0)
 {
  double tmpinfo2 = MarketInfo(StringSubstr(Symbol(), 0, 3)+"USD",MODE_BID);
  marginsum = ((100-stopout_level)/100)*MathAbs(AccountBalance()-calc_margin*tmpinfo2);
 proff = preproff*calc_lots*tikk_l*tmpinfo2 ;
  loss = preloss*calc_lots*tikk_l*tmpinfo2 ;
   stopout_lvl = ObjectGet("OPEN", OBJPROP_PRICE1) + marginsum/(calc_lots*tikk_l*tmpinfo2);
  stopout_lvl2 = ObjectGet("OPEN", OBJPROP_PRICE1) - marginsum/(calc_lots*tikk_l*tmpinfo2);

  if (start_margin<=0)start_margin = (calc_lots*tikk_l/leverage_lev)*tmpinfo2;
 }
 else
 {
 //////
   int xxx = 1;
   if (StringSubstr(Symbol(), 3, 3)=="CAD") xxx=1.2175;
   if (StringSubstr(Symbol(), 3, 3)=="JPY") xxx=91.425;
   if (StringSubstr(Symbol(), 3, 3)=="CHF") xxx=1.1631;
   if (StringSubstr(Symbol(), 3, 3)=="AUD") xxx=1/0.6800;
   if (StringSubstr(Symbol(), 3, 3)=="NZD") xxx=1/0.54;
   if (StringSubstr(Symbol(), 3, 3)=="GPB") xxx=1/1.49;
   if (StringSubstr(Symbol(), 3, 3)=="EUR") xxx=1/1.3015;
   marginsum = ((100-stopout_level)/100)*MathAbs(AccountBalance()-calc_margin/xxx);
   proff = preproff*calc_lots*tikk_v/tikk_s;
   loss = preloss*calc_lots*tikk_v/tikk_s;
   stopout_lvl =  ObjectGet("OPEN", OBJPROP_PRICE1) + marginsum/(calc_lots*tikk_v/(tikk_s/xxx));
   stopout_lvl2 = ObjectGet("OPEN", OBJPROP_PRICE1) - marginsum/(calc_lots*tikk_v/(tikk_s/xxx));
 ///// 
 } 
 }
  
 }
 break;
case 1: //CFD стоки
double temp3 = ObjectGet("OPEN", OBJPROP_PRICE1);
 
   proff = preproff*calc_lots*tikk_l - (comission/100)*calc_lots*temp3;
   loss  = preloss*calc_lots*tikk_l  + (comission/100)*calc_lots*temp3;
   stopout_lvl = temp3 + (marginsum-(comission/100)*calc_lots*temp3)/(calc_lots*tikk_l);
  stopout_lvl2 = temp3 - (marginsum-(comission/100)*calc_lots*temp3)/(calc_lots*tikk_l);

 break;
 default: // фьючи
   proff =( preproff*calc_lots*tikk_v/tikk_s) - (calc_lots*comission);
   loss = (  preloss*calc_lots*tikk_v/tikk_s) + (calc_lots*comission);
   stopout_lvl = ObjectGet("OPEN", OBJPROP_PRICE1) + (marginsum/kurs-calc_lots*comission)/(calc_lots*tikk_v/tikk_s);
  stopout_lvl2 = ObjectGet("OPEN", OBJPROP_PRICE1) - (marginsum/kurs-calc_lots*comission)/(calc_lots*tikk_v/tikk_s);

  marginsum = marginsum/kurs;

 break;
 }
//установка линии стопаута
 if (ObjectGet("OPEN", OBJPROP_PRICE1)>ObjectGet("PROFIT", OBJPROP_PRICE1))
{
if (ObjectFind("STOPOUT") == -1) ObjectCreate("STOPOUT" , OBJ_HLINE,0,0,stopout_lvl);
ObjectSet("STOPOUT", OBJPROP_PRICE1, stopout_lvl);
}
else
{
if (ObjectFind("STOPOUT") == -1) ObjectCreate("STOPOUT" , OBJ_HLINE,0,0,stopout_lvl2);
ObjectSet("STOPOUT", OBJPROP_PRICE1, stopout_lvl2);
}




 // пояснительные текста на линии
ObjectSetText("STOPOUT", "Уровень стопаута -"+DoubleToStr(marginsum, 2)+"USD", 10, "Times New Roman", Green);
 
  ObjectSetText("OPEN", "                            Open "+DoubleToStr(calc_lots,2)+" лотов", 10, "Times New Roman", Green);
  ObjectSetText("STOP", "Stop "+DoubleToStr(loss, 2), 10, "Times New Roman", Green);
  ObjectSetText("PROFIT", "Profit "+DoubleToStr(proff, 2), 10, "Times New Roman", Green);
 
//вывод в левый верхний угол значений калькулятора   
  comnts = "Для "+ DoubleToStr(calc_lots,2) + " лотов Профит: " + DoubleToStr(proff,2) +" ("+DoubleToStr(proff*100/AccountEquity(), 2)+"%) "+ " Лосс: " + DoubleToStr(loss, 2)+" ("+DoubleToStr(loss*100/AccountEquity(), 2)+"%) ";
   if (start_margin>0) comnts = comnts + "Стартовая маржа: "+DoubleToStr(start_margin,2)+" USD";
  if (leverage_lev>0) comnts = comnts + " Плечо: " + DoubleToStr(leverage_lev,2);
  Comment(comnts);
    
   return(0);
  }

