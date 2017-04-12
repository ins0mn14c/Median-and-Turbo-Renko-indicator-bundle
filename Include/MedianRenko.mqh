//+------------------------------------------------------------------+
//|                                         MedianRenko.mqh ver:1.46 |
//|                                        Copyright 2017, AZ-iNVEST |
//|                                          http://www.az-invest.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, AZ-iNVEST"
#property link      "http://www.az-invest.eu"

#define RENKO_INDICATOR_NAME "Market\\Median and Turbo renko indicator bundle" 

#define RENKO_MA1 0
#define RENKO_MA2 1
#define RENKO_CHANNEL_HIGH 2
#define RENKO_CHANNEL_MID 3
#define RENKO_CHANNEL_LOW 4
#define RENKO_OPEN 5
#define RENKO_HIGH 6
#define RENKO_LOW 7
#define RENKO_CLOSE 8
#define RENKO_BAR_OPEN_TIME 9
#define RENKO_TICK_VOLUME 10

#include <MedianRenkoSettings.mqh>

class MedianRenko
{
   private:
   
      MedianRenkoSettings * medianRenkoSettings;

      //
      //  Median renko indicator handle
      //
      
      int medianRenkoHandle;
      string medianRenkoSymbol;
   
   public:
      
      MedianRenko();   
      MedianRenko(string symbol);
      ~MedianRenko(void);
      
      int Init();
      void Deinit();
      bool Reload();
      
      int GetHandle(void) { return medianRenkoHandle; };
      bool GetMqlRates(MqlRates &ratesInfoArray[], int start, int count);
      int GetOLHCForIndicatorCalc(double &o[],double &l[],double &h[],double &c[], int start, int count);
      bool GetMA1(double &MA[], int start, int count);
      bool GetMA2(double &MA[], int start, int count);
      bool GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
      bool GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
           
      bool IsNewBar();
      
   private:

      bool GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count);
   
};

MedianRenko::MedianRenko(void)
{
   medianRenkoSettings = new MedianRenkoSettings();
   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = _Symbol;
}

MedianRenko::MedianRenko(string symbol)
{
   medianRenkoSettings = new MedianRenkoSettings();
   medianRenkoHandle = INVALID_HANDLE;
   medianRenkoSymbol = symbol;
}

MedianRenko::~MedianRenko(void)
{
   if(medianRenkoSettings != NULL)
      delete medianRenkoSettings;
}

//
//  Function for initializing the median renko indicator handle
//

int MedianRenko::Init()
{
   if(!medianRenkoSettings.Load())
   {
      if(medianRenkoHandle != INVALID_HANDLE)
      {
         // could not read new settings - keep old settings
         
         return medianRenkoHandle;
      }
      else
      {
         Print("Failed to load indicator settings.");
         Alert("You need to put the Median Renko indicator on your chart first!");
         return INVALID_HANDLE;
      }
   }   
   
   if(medianRenkoHandle != INVALID_HANDLE)
      Deinit();
   
   MEDIANRENKO_SETTINGS s = medianRenkoSettings.Get();
   //medianRenkoSettings.Debug();
   
   medianRenkoHandle = iCustom(this.medianRenkoSymbol,PERIOD_M1,RENKO_INDICATOR_NAME, 
                                       s.barSizeInTicks,
                                       s._retracementFactor,
                                       s.symetricalReversals,
                                       s.showWicks,
                                       s._startFromDateTime,
                                       s.resetOpenOnNewTradingDay,
                                       showNextBarLevels,
                                       HighThresholdIndicatorColor,
                                       LowThresholdIndicatorColor,
                                       showCurrentBarOpenTime,
                                       InfoTextColor,
                                       UseSoundSignalOnNewBar,
                                       OnlySignalReversalBars,
                                       UseAlertWindow,
                                       SendPushNotifications,
                                       SoundFileBull,
                                       SoundFileBear,
                                       s.MA1on, 
                                       s.MA1period,
                                       s.MA1method,
                                       s.MA1applyTo,
                                       s.MA1shift,
                                       s.MA2on,
                                       s.MA2period,
                                       s.MA2method,
                                       s.MA2applyTo,
                                       s.MA2shift,
                                       s.ShowChannel,
                                       "",
                                       s.DonchianPeriod,
                                       s.BBapplyTo,
                                       s.BollingerBandsPeriod,
                                       s.BollingerBandsDeviations,
                                       s.SuperTrendPeriod,
                                       s.SuperTrendMultiplier,
                                       "",
                                       UsedInEA);
  
    
    if(medianRenkoHandle == INVALID_HANDLE)
    {
      Print("Median Renko indicator init failed on error ",GetLastError());
    }
    else
    {
      Print("Median Renko indicator init OK");
    }
     
    return medianRenkoHandle;
}

//
// Function for reloading the Median Renko indicator if needed
//

bool MedianRenko::Reload()
{
   if(medianRenkoSettings.Changed())
   {
      if(Init() == INVALID_HANDLE)
         return false;
      
      return true;
   }
   
   return false;
}

//
// Function for releasing the Median Renko indicator hanlde - free resources
//

void MedianRenko::Deinit()
{
   if(medianRenkoHandle == INVALID_HANDLE)
      return;
      
   if(IndicatorRelease(medianRenkoHandle))
      Print("Median Rneko indicator handle released");
   else 
      Print("Failed to release Median Renko indicator handle");
}

//
// Function for detecting a new Renko bar
//

bool MedianRenko::IsNewBar()
{
   MqlRates currentRenko[1];
   static MqlRates prevRenko;
   
   GetMqlRates(currentRenko,1,1);
   
   if((prevRenko.open != currentRenko[0].open) ||
      (prevRenko.high != currentRenko[0].high) ||
      (prevRenko.low != currentRenko[0].low) ||
      (prevRenko.close != currentRenko[0].close))
   {
      prevRenko.open = currentRenko[0].open;
      prevRenko.high = currentRenko[0].high;
      prevRenko.low = currentRenko[0].low;
      prevRenko.close = currentRenko[0].close;
      return true;
   }
   
   return false;
}

//
// Get "count" Renko MqlRates into "ratesInfoArray[]" array starting from "start" bar  
//

bool MedianRenko::GetMqlRates(MqlRates &ratesInfoArray[], int start, int count)
{
   double o[],l[],h[],c[],time[],tick_volume[];

   if(ArrayResize(o,count) == -1)
      return false;
   if(ArrayResize(l,count) == -1)
      return false;
   if(ArrayResize(h,count) == -1)
      return false;
   if(ArrayResize(c,count) == -1)
      return false;
   if(ArrayResize(time,count) == -1)
      return false;
   if(ArrayResize(tick_volume,count) == -1)
      return false;

  
   if(CopyBuffer(medianRenkoHandle,RENKO_OPEN,start,count,o) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_LOW,start,count,l) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_HIGH,start,count,h) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_CLOSE,start,count,c) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_BAR_OPEN_TIME,start,count,time) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_TICK_VOLUME,start,count,tick_volume) == -1)
      return false;

   if(ArrayResize(ratesInfoArray,count) == -1)
      return false; 

   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      ratesInfoArray[tempOffset-i].open = o[i];
      ratesInfoArray[tempOffset-i].low = l[i];
      ratesInfoArray[tempOffset-i].high = h[i];
      ratesInfoArray[tempOffset-i].close = c[i];
      ratesInfoArray[tempOffset-i].time = (datetime)time[i];
      ratesInfoArray[tempOffset-i].tick_volume = (long)tick_volume[i];
   }
   
   ArrayFree(o);
   ArrayFree(l);
   ArrayFree(h);
   ArrayFree(c);
   ArrayFree(time);
   ArrayFree(tick_volume);   
   
   return true;
}

//
// Get "count" Renko MqlRates into "ratesInfoArray[]" array starting from "start" bar  
//

int MedianRenko::GetOLHCForIndicatorCalc(double &o[],double &l[],double &h[],double &c[], int start, int count)
{
   if(ArrayResize(o,count) == -1)
      return false;

   int _count = CopyBuffer(medianRenkoHandle,RENKO_OPEN,start,count,o);
   if(_count == -1)
      return _count;


   if(ArrayResize(o,_count) == -1)
      return -1;
   if(ArrayResize(l,_count) == -1)
      return -1;
   if(ArrayResize(h,_count) == -1)
      return -1;
   if(ArrayResize(c,_count) == -1)
      return -1;
  
   if(CopyBuffer(medianRenkoHandle,RENKO_OPEN,start,_count,o) == -1)
      return -1;
   if(CopyBuffer(medianRenkoHandle,RENKO_LOW,start,_count,l) == -1)
      return -1;
   if(CopyBuffer(medianRenkoHandle,RENKO_HIGH,start,_count,h) == -1)
      return -1;
   if(CopyBuffer(medianRenkoHandle,RENKO_CLOSE,start,_count,c) == -1)
      return -1;
   
   return _count;
}

//
// Get "count" MovingAverage1 values into "MA[]" array starting from "start" bar  
//

bool MedianRenko::GetMA1(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(medianRenkoHandle,RENKO_MA1,start,count,tempMA) == -1)
      return false;

   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }

   ArrayFree(tempMA);      
   return true;
}

//
// Get "count" MovingAverage2 values into "MA[]" starting from "start" bar  
//

bool MedianRenko::GetMA2(double &MA[], int start, int count)
{
   double tempMA[];
   if(ArrayResize(tempMA,count) == -1)
      return false;

   if(ArrayResize(MA,count) == -1)
      return false;
   
   if(CopyBuffer(medianRenkoHandle,RENKO_MA2,start,count,tempMA) == -1)
      return false;
   
   for(int i=0; i<count; i++)
   {
      MA[count-1-i] = tempMA[i];
   }
   
   ArrayFree(tempMA);   
   return true;
}

//
// Get "count" Renko Donchian channel values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetDonchian(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Get "count" Bollinger band values into "HighArray[]", "MidArray[]", and "LowArray[]" arrays starting from "start" bar  
//

bool MedianRenko::GetBollingerBands(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   return GetChannel(HighArray,MidArray,LowArray,start,count);
}

//
// Private function used by GetRenkoDonchian and GetRenkoBollingerBands functions to get data
//

bool MedianRenko::GetChannel(double &HighArray[], double &MidArray[], double &LowArray[], int start, int count)
{
   double tempH[], tempM[], tempL[];

   if(ArrayResize(tempH,count) == -1)
      return false;
   if(ArrayResize(tempM,count) == -1)
      return false;
   if(ArrayResize(tempL,count) == -1)
      return false;

   if(ArrayResize(HighArray,count) == -1)
      return false;
   if(ArrayResize(MidArray,count) == -1)
      return false;
   if(ArrayResize(LowArray,count) == -1)
      return false;
   
   if(CopyBuffer(medianRenkoHandle,RENKO_CHANNEL_HIGH,start,count,tempH) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_CHANNEL_MID,start,count,tempM) == -1)
      return false;
   if(CopyBuffer(medianRenkoHandle,RENKO_CHANNEL_LOW,start,count,tempL) == -1)
      return false;
   
   int tempOffset = count-1;
   for(int i=0; i<count; i++)
   {
      HighArray[tempOffset-i] = tempH[i];
      MidArray[tempOffset-i] = tempM[i];
      LowArray[tempOffset-i] = tempL[i];
   }   
   
   ArrayFree(tempH);
   ArrayFree(tempM);
   ArrayFree(tempL);
   
   return true;
}