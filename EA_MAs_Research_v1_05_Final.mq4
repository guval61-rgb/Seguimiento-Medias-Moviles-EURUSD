//+------------------------------------------------------------------+
//|                                   EA_MAs_Research_v105_FINAL.mq4 |
//|                                   Expert Advisor de Investigación|
//|                          Sistema de Medias Móviles Multi-Salida  |
//+------------------------------------------------------------------+
#property copyright "Guido - Investigación MAs"
#property version   "1.05"
#property strict

//+------------------------------------------------------------------+
//| PARÁMETROS EXTERNOS                                               |
//+------------------------------------------------------------------+
extern string    S1 = "===== CONFIGURACIÓN GENERAL =====";
extern int       MagicNumber = 12345;
extern bool      OperarSoloEnNuevaBarra = true;

extern string    S2 = "===== COMBINACIONES A EVALUAR =====";
extern bool      Eval_Combinacion_A = true;  // a+b+c+d
extern bool      Eval_Combinacion_B = true;  // a+b+c
extern bool      Eval_Combinacion_C = true;  // a+b+d
extern bool      Eval_Combinacion_D = true;  // a+c+d
extern bool      Eval_Combinacion_E = true;  // a+d+e

extern string    S3 = "===== SALIDAS PIPS FIJOS =====";
extern bool      Salida_Pips_5 = true;
extern bool      Salida_Pips_10 = true;
extern bool      Salida_Pips_15 = true;
extern bool      Salida_Pips_20 = true;
extern bool      Salida_Pips_25 = true;
extern bool      Salida_Pips_30 = true;
extern bool      Salida_Pips_35 = true;
extern bool      Salida_Pips_40 = true;
extern bool      Salida_Pips_50 = true;
extern bool      Salida_Pips_55 = true;
extern bool      Salida_Pips_60 = true;
extern bool      Salida_Pips_65 = true;
extern bool      Salida_Pips_70 = true;
extern bool      Salida_Pips_75 = true;
extern bool      Salida_Pips_80 = true;
extern bool      Salida_Pips_85 = true;
extern bool      Salida_Pips_90 = true;
extern bool      Salida_Pips_100 = true;
extern bool      Salida_Pips_Plus100 = true;

extern string    S4 = "===== SALIDAS RETROCESO =====";
extern bool      Salida_Retroceso_20 = true;
extern bool      Salida_Retroceso_25 = true;
extern bool      Salida_Retroceso_30 = true;
extern bool      Salida_Retroceso_35 = true;
extern bool      Salida_Retroceso_40 = true;
extern bool      Salida_Retroceso_45 = true;
extern bool      Salida_Retroceso_50 = true;

extern string    S5 = "===== SALIDAS CRUCES INVERSOS (5 salidas) =====";
extern bool      Salida_Cruce_a = true;  // LWMA200 vs LWMA220
extern bool      Salida_Cruce_b = true;  // LWMA100 vs LWMA105
extern bool      Salida_Cruce_c = true;  // LWMA50 vs LWMA53
extern bool      Salida_Cruce_d = true;  // LWMA20 vs LWMA22
extern bool      Salida_Cruce_e = true;  // Precio vs SMA5

extern string    S6 = "===== CONFIGURACIÓN =====";
extern double    UmbralMinimoPips = 1.0;

extern string    S7 = "===== EXPORT Y LOGGING =====";
extern bool      ExportarCSV = true;
extern bool      LoggingDetallado = true;
extern int       BarsHistoriaMinima = 250;
extern int       BufferCSV_Lineas = 100;

//+------------------------------------------------------------------+
//| VARIABLES GLOBALES                                                |
//+------------------------------------------------------------------+
datetime LastBarTime = 0;
int FileHandleSeñales = -1;
int FileHandleResumen = -1;
double PipValue = 1.0;
int SimboloDigits = 0;
string SimboloActual = "";

int ContadorIDSeñales = 0;
int TotalSeñalesDetectadas = 0;
int TotalTradesActivos = 0;

struct MediasMoviles {
    double ma200_close;
    double ma220_open;
    double ma100_close;
    double ma105_open;
    double ma50_close;
    double ma53_open;
    double ma20_close;
    double ma22_open;
    double ma5_close;
};

MediasMoviles MAsCache;
bool MAsCacheValido = false;
string BufferCSVResumen = "";
int ContadorBufferResumen = 0;

//+------------------------------------------------------------------+
//| ESTRUCTURA - Información de salida individual                     |
//+------------------------------------------------------------------+
struct InfoSalida {
    bool      cerrada;
    datetime  timestamp;
    double    precio;
    double    pips;
    int       bars;
};

//+------------------------------------------------------------------+
//| ESTRUCTURA DE DATOS PARA TRACKING VIRTUAL - v1.04                 |
//+------------------------------------------------------------------+
struct TradeVirtual {
    int       id;
    datetime  timestamp_entrada;
    string    tipo;
    string    combinacion;
    double    precio_entrada;
    double    pips_actual;
    double    pips_maximo;
    double    pips_minimo;
    double    precio_maximo;
    double    precio_minimo;
    datetime  timestamp_maximo;
    int       bars_duracion;
    
    // Salidas Pips - 19 salidas
    InfoSalida salida_pips_5_info;
    InfoSalida salida_pips_10_info;
    InfoSalida salida_pips_15_info;
    InfoSalida salida_pips_20_info;
    InfoSalida salida_pips_25_info;
    InfoSalida salida_pips_30_info;
    InfoSalida salida_pips_35_info;
    InfoSalida salida_pips_40_info;
    InfoSalida salida_pips_50_info;
    InfoSalida salida_pips_55_info;
    InfoSalida salida_pips_60_info;
    InfoSalida salida_pips_65_info;
    InfoSalida salida_pips_70_info;
    InfoSalida salida_pips_75_info;
    InfoSalida salida_pips_80_info;
    InfoSalida salida_pips_85_info;
    InfoSalida salida_pips_90_info;
    InfoSalida salida_pips_100_info;
    InfoSalida salida_pips_plus100_info;
    
    // Salidas Retroceso - 7 salidas
    InfoSalida salida_retroceso_20_info;
    InfoSalida salida_retroceso_25_info;
    InfoSalida salida_retroceso_30_info;
    InfoSalida salida_retroceso_35_info;
    InfoSalida salida_retroceso_40_info;
    InfoSalida salida_retroceso_45_info;
    InfoSalida salida_retroceso_50_info;
    
    // Salidas Cruces - 5 salidas
    InfoSalida salida_cruce_a_info;
    InfoSalida salida_cruce_b_info;
    InfoSalida salida_cruce_c_info;
    InfoSalida salida_cruce_d_info;
    InfoSalida salida_cruce_e_info;
    
    // Salidas Timeouts - 17 salidas
    InfoSalida salida_timeout_25_info;
    InfoSalida salida_timeout_50_info;
    InfoSalida salida_timeout_75_info;
    InfoSalida salida_timeout_100_info;
    InfoSalida salida_timeout_125_info;
    InfoSalida salida_timeout_150_info;
    InfoSalida salida_timeout_175_info;
    InfoSalida salida_timeout_200_info;
    InfoSalida salida_timeout_225_info;
    InfoSalida salida_timeout_250_info;
    InfoSalida salida_timeout_275_info;
    InfoSalida salida_timeout_300_info;
    InfoSalida salida_timeout_325_info;
    InfoSalida salida_timeout_350_info;
    InfoSalida salida_timeout_400_info;
    InfoSalida salida_timeout_450_info;
    InfoSalida salida_timeout_500_info;
    
    // Salidas StopLoss - 20 salidas
    InfoSalida salida_sl_5_info;
    InfoSalida salida_sl_10_info;
    InfoSalida salida_sl_20_info;
    InfoSalida salida_sl_30_info;
    InfoSalida salida_sl_40_info;
    InfoSalida salida_sl_50_info;
    InfoSalida salida_sl_60_info;
    InfoSalida salida_sl_70_info;
    InfoSalida salida_sl_80_info;
    InfoSalida salida_sl_90_info;
    InfoSalida salida_sl_100_info;
    InfoSalida salida_sl_120_info;
    InfoSalida salida_sl_130_info;
    InfoSalida salida_sl_140_info;
    InfoSalida salida_sl_150_info;
    InfoSalida salida_sl_160_info;
    InfoSalida salida_sl_170_info;
    InfoSalida salida_sl_180_info;
    InfoSalida salida_sl_190_info;
    InfoSalida salida_sl_200_info;
    
    // Salida Señal Contraria - 1 salida
    InfoSalida salida_senal_contraria_info;
    
    // MAs al entry y exit
    double    ma200_entry, ma220_entry, ma100_entry, ma105_entry;
    double    ma50_entry, ma53_entry, ma20_entry, ma22_entry, ma5_entry;
    double    ma200_exit, ma220_exit, ma100_exit, ma105_exit;
    double    ma50_exit, ma53_exit, ma20_exit, ma22_exit, ma5_exit;
    
    int       hora_entrada;
    int       dia_semana_entrada;
    
    bool      activo;
    bool      todas_salidas_cerradas;
};

// Arrays de tracking virtual - 5 combinaciones
TradeVirtual TrackingBUY_A, TrackingBUY_B, TrackingBUY_C, TrackingBUY_D, TrackingBUY_E;
TradeVirtual TrackingSELL_A, TrackingSELL_B, TrackingSELL_C, TrackingSELL_D, TrackingSELL_E;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    Print("==================================================");
    Print("EA_MAs_Research_v1.05 - INICIANDO");
    
    SimboloActual = Symbol();
    SimboloDigits = Digits;
    
    Print("Símbolo: ", SimboloActual);
    Print("Timeframe: ", PeriodToString(Period()));
    Print("Magic Number: ", MagicNumber);
    Print("==================================================");
    
    CalcularPipValue();
    Print("Valor de 1 pip: ", DoubleToString(PipValue, SimboloDigits), 
          " (Dígitos: ", SimboloDigits, ")");
    
    int bars = Bars;
    if(bars < BarsHistoriaMinima) {
        Print("ERROR: Historia insuficiente. Bars disponibles: ", bars, 
              " - Mínimo requerido: ", BarsHistoriaMinima);
        return(INIT_FAILED);
    }
    Print("Bars disponibles: ", bars);
    
    if(Bars > 0) {
        LastBarTime = Time[0];
    } else {
        Print("ERROR: No hay barras disponibles");
        return(INIT_FAILED);
    }
    
    if(ExportarCSV) {
        if(!InicializarArchivosCSV()) {
            Print("ERROR: No se pudieron inicializar archivos CSV");
            return(INIT_FAILED);
        }
    }
    
    InicializarTrackingVirtual();
    ContadorIDSeñales = 0;
    MAsCacheValido = false;
    
    Print("SALIDAS CONFIGURADAS:");
    Print("- Pips fijos: 19 salidas");
    Print("- Retrocesos: 7 salidas");
    Print("- Cruces: 5 salidas");
    Print("- Timeouts: 17 salidas");
    Print("- StopLoss: 20 salidas");
    Print("- Señal contraria: 1 salida");
    Print("TOTAL: 69 salidas virtuales simultáneas");
    Print("==================================================");
    Print("EA_MAs_Research_v1.05 - INICIALIZADO CORRECTAMENTE");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("==================================================");
    Print("EA_MAs_Research_v1.05 - FINALIZANDO");
    Print("Razón: ", reason);
    Print("Total Señales Detectadas: ", TotalSeñalesDetectadas);
    
    if(BufferCSVResumen != "" && FileHandleResumen >= 0) {
        FileWriteString(FileHandleResumen, BufferCSVResumen);
        BufferCSVResumen = "";
    }
    
    Print("==================================================");
    
    if(FileHandleSeñales >= 0) {
        FileFlush(FileHandleSeñales);
        FileClose(FileHandleSeñales);
    }
    if(FileHandleResumen >= 0) {
        FileFlush(FileHandleResumen);
        FileClose(FileHandleResumen);
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    if(OperarSoloEnNuevaBarra) {
        if(Time[0] == LastBarTime) return;
        LastBarTime = Time[0];
    }
    
    if(Bars < BarsHistoriaMinima || Bars < 2) return;
    
    MAsCacheValido = false;
    
    bool hayTrackingActivo = (TrackingBUY_A.activo || TrackingBUY_B.activo || TrackingBUY_C.activo || 
                              TrackingBUY_D.activo || TrackingBUY_E.activo ||
                              TrackingSELL_A.activo || TrackingSELL_B.activo || TrackingSELL_C.activo || 
                              TrackingSELL_D.activo || TrackingSELL_E.activo);
    
    MediasMoviles mas;
    if(!ObtenerMAsConCache(mas)) {
        if(LoggingDetallado) {
            Print("ERROR: No se pudieron calcular medias móviles en bar ", Time[0]);
        }
        return;
    }
    
    EvaluarTodasLasSeñales(mas);
    
    if(hayTrackingActivo) {
        ActualizarTodosLosTrackings(mas);
    }
}

//+------------------------------------------------------------------+
//| OPTIMIZACIÓN: Obtener MAs con caché                               |
//+------------------------------------------------------------------+
bool ObtenerMAsConCache(MediasMoviles &mas) {
    if(MAsCacheValido) {
        mas = MAsCache;
        return true;
    }
    
    if(!CalcularMediasMoviles(mas)) {
        return false;
    }
    
    MAsCache = mas;
    MAsCacheValido = true;
    return true;
}

//+------------------------------------------------------------------+
//| OPTIMIZACIÓN: Evaluar todas las señales en un solo bloque         |
//+------------------------------------------------------------------+
void EvaluarTodasLasSeñales(MediasMoviles &mas) {
    bool cond_a = EvaluarCondicion_a(mas);
    bool cond_b = EvaluarCondicion_b(mas);
    bool cond_c = EvaluarCondicion_c(mas);
    bool cond_d = EvaluarCondicion_d(mas);
    bool cond_e = EvaluarCondicion_e(mas);
    
    bool cond_a_sell = EvaluarCondicion_a_Inversa(mas);
    bool cond_b_sell = EvaluarCondicion_b_Inversa(mas);
    bool cond_c_sell = EvaluarCondicion_c_Inversa(mas);
    bool cond_d_sell = EvaluarCondicion_d_Inversa(mas);
    bool cond_e_sell = EvaluarCondicion_e_Inversa(mas);
    
    // BUY
    if(Eval_Combinacion_A) {
        bool señal_buy_A = cond_a && cond_b && cond_c && cond_d;
        ProcesarSeñal(señal_buy_A, "BUY", "A", mas, TrackingBUY_A, 
                     cond_a, cond_b, cond_c, cond_d, cond_e);
    }
    
    if(Eval_Combinacion_B) {
        bool señal_buy_B = cond_a && cond_b && cond_c;
        ProcesarSeñal(señal_buy_B, "BUY", "B", mas, TrackingBUY_B,
                     cond_a, cond_b, cond_c, cond_d, cond_e);
    }
    
    if(Eval_Combinacion_C) {
        bool señal_buy_C = cond_a && cond_b && cond_d;
        ProcesarSeñal(señal_buy_C, "BUY", "C", mas, TrackingBUY_C,
                     cond_a, cond_b, cond_c, cond_d, cond_e);
    }
    
    if(Eval_Combinacion_D) {
        bool señal_buy_D = cond_a && cond_c && cond_d;
        ProcesarSeñal(señal_buy_D, "BUY", "D", mas, TrackingBUY_D,
                     cond_a, cond_b, cond_c, cond_d, cond_e);
    }
    
    if(Eval_Combinacion_E) {
        bool señal_buy_E = cond_a && cond_d && cond_e;
        ProcesarSeñal(señal_buy_E, "BUY", "E", mas, TrackingBUY_E,
                     cond_a, cond_b, cond_c, cond_d, cond_e);
    }
    
    // SELL
    if(Eval_Combinacion_A) {
        bool señal_sell_A = cond_a_sell && cond_b_sell && cond_c_sell && cond_d_sell;
        ProcesarSeñal(señal_sell_A, "SELL", "A", mas, TrackingSELL_A,
                     cond_a_sell, cond_b_sell, cond_c_sell, cond_d_sell, cond_e_sell);
    }
    
    if(Eval_Combinacion_B) {
        bool señal_sell_B = cond_a_sell && cond_b_sell && cond_c_sell;
        ProcesarSeñal(señal_sell_B, "SELL", "B", mas, TrackingSELL_B,
                     cond_a_sell, cond_b_sell, cond_c_sell, cond_d_sell, cond_e_sell);
    }
    
    if(Eval_Combinacion_C) {
        bool señal_sell_C = cond_a_sell && cond_b_sell && cond_d_sell;
        ProcesarSeñal(señal_sell_C, "SELL", "C", mas, TrackingSELL_C,
                     cond_a_sell, cond_b_sell, cond_c_sell, cond_d_sell, cond_e_sell);
    }
    
    if(Eval_Combinacion_D) {
        bool señal_sell_D = cond_a_sell && cond_c_sell && cond_d_sell;
        ProcesarSeñal(señal_sell_D, "SELL", "D", mas, TrackingSELL_D,
                     cond_a_sell, cond_b_sell, cond_c_sell, cond_d_sell, cond_e_sell);
    }
    
    if(Eval_Combinacion_E) {
        bool señal_sell_E = cond_a_sell && cond_d_sell && cond_e_sell;
        ProcesarSeñal(señal_sell_E, "SELL", "E", mas, TrackingSELL_E,
                     cond_a_sell, cond_b_sell, cond_c_sell, cond_d_sell, cond_e_sell);
    }
}

//+------------------------------------------------------------------+
//| OPTIMIZACIÓN: Actualizar todos los trackings en bloque            |
//+------------------------------------------------------------------+
void ActualizarTodosLosTrackings(MediasMoviles &mas) {
    if(TrackingBUY_A.activo) ActualizarTrackingVirtual(TrackingBUY_A, mas);
    if(TrackingBUY_B.activo) ActualizarTrackingVirtual(TrackingBUY_B, mas);
    if(TrackingBUY_C.activo) ActualizarTrackingVirtual(TrackingBUY_C, mas);
    if(TrackingBUY_D.activo) ActualizarTrackingVirtual(TrackingBUY_D, mas);
    if(TrackingBUY_E.activo) ActualizarTrackingVirtual(TrackingBUY_E, mas);
    
    if(TrackingSELL_A.activo) ActualizarTrackingVirtual(TrackingSELL_A, mas);
    if(TrackingSELL_B.activo) ActualizarTrackingVirtual(TrackingSELL_B, mas);
    if(TrackingSELL_C.activo) ActualizarTrackingVirtual(TrackingSELL_C, mas);
    if(TrackingSELL_D.activo) ActualizarTrackingVirtual(TrackingSELL_D, mas);
    if(TrackingSELL_E.activo) ActualizarTrackingVirtual(TrackingSELL_E, mas);
}

//+------------------------------------------------------------------+
//| Calcular valor de 1 pip del símbolo actual                        |
//+------------------------------------------------------------------+
void CalcularPipValue() {
    if(Digits == 5 || Digits == 3) {
        PipValue = Point * 10;
    } else {
        PipValue = Point;
    }
}

//+------------------------------------------------------------------+
//| Calcular MAs con validación de errores                            |
//+------------------------------------------------------------------+
bool CalcularMediasMoviles(MediasMoviles &mas) {
    ResetLastError();
    
    mas.ma200_close = iMA(NULL, 0, 200, 0, MODE_LWMA, PRICE_CLOSE, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma220_open  = iMA(NULL, 0, 220, 0, MODE_LWMA, PRICE_OPEN, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma100_close = iMA(NULL, 0, 100, 0, MODE_LWMA, PRICE_CLOSE, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma105_open  = iMA(NULL, 0, 105, 0, MODE_LWMA, PRICE_OPEN, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma50_close  = iMA(NULL, 0, 50, 0, MODE_LWMA, PRICE_CLOSE, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma53_open   = iMA(NULL, 0, 53, 0, MODE_LWMA, PRICE_OPEN, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma20_close  = iMA(NULL, 0, 20, 0, MODE_LWMA, PRICE_CLOSE, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma22_open   = iMA(NULL, 0, 22, 0, MODE_LWMA, PRICE_OPEN, 1);
    if(GetLastError() != 0) return false;
    
    mas.ma5_close   = iMA(NULL, 0, 5, 0, MODE_SMA, PRICE_CLOSE, 1);
    if(GetLastError() != 0) return false;
    
    if(mas.ma200_close <= 0 || mas.ma220_open <= 0 || mas.ma100_close <= 0 ||
       mas.ma105_open <= 0 || mas.ma50_close <= 0 || mas.ma53_open <= 0 ||
       mas.ma20_close <= 0 || mas.ma22_open <= 0 || mas.ma5_close <= 0) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Evaluar condiciones individuales                                  |
//+------------------------------------------------------------------+
bool EvaluarCondicion_a(MediasMoviles &mas) { return (mas.ma200_close > mas.ma220_open); }
bool EvaluarCondicion_b(MediasMoviles &mas) { return (mas.ma100_close > mas.ma105_open); }
bool EvaluarCondicion_c(MediasMoviles &mas) { return (mas.ma50_close > mas.ma53_open); }
bool EvaluarCondicion_d(MediasMoviles &mas) { return (mas.ma20_close > mas.ma22_open); }
bool EvaluarCondicion_e(MediasMoviles &mas) { 
    if(Bars < 2) return false;
    return (Close[1] > mas.ma5_close); 
}

bool EvaluarCondicion_a_Inversa(MediasMoviles &mas) { return (mas.ma200_close < mas.ma220_open); }
bool EvaluarCondicion_b_Inversa(MediasMoviles &mas) { return (mas.ma100_close < mas.ma105_open); }
bool EvaluarCondicion_c_Inversa(MediasMoviles &mas) { return (mas.ma50_close < mas.ma53_open); }
bool EvaluarCondicion_d_Inversa(MediasMoviles &mas) { return (mas.ma20_close < mas.ma22_open); }
bool EvaluarCondicion_e_Inversa(MediasMoviles &mas) { 
    if(Bars < 2) return false;
    return (Close[1] < mas.ma5_close); 
}

//+------------------------------------------------------------------+
//| Procesar señal detectada                                          |
//+------------------------------------------------------------------+
void ProcesarSeñal(bool señal_activa, string tipo, string combinacion, 
                   MediasMoviles &mas, TradeVirtual &tracking,
                   bool cond_a, bool cond_b, bool cond_c, bool cond_d, bool cond_e) {
    
    if(ExportarCSV && señal_activa) {
        string razon_no_iniciado = "";
        bool tracking_iniciado = false;
        
        if(!tracking.activo) {
            tracking_iniciado = true;
        } else {
            razon_no_iniciado = "TRACKING_YA_ACTIVO";
        }
        
        RegistrarSeñalDetallada(tipo, combinacion, mas, tracking_iniciado, razon_no_iniciado,
                               cond_a, cond_b, cond_c, cond_d, cond_e);
        TotalSeñalesDetectadas++;
    }
    
    if(señal_activa && !tracking.activo) {
        IniciarTrackingVirtual(tracking, tipo, combinacion, mas);
        
        if(LoggingDetallado) {
            Print("SEÑAL ", tipo, " - Combinación ", combinacion, 
                  " | Precio: ", DoubleToString(Close[1], SimboloDigits),
                  " | Timestamp: ", TimeToString(Time[1]));
        }
    }
}

//+------------------------------------------------------------------+
//| Iniciar tracking virtual                                          |
//+------------------------------------------------------------------+
void IniciarTrackingVirtual(TradeVirtual &tracking, string tipo, 
                            string combinacion, MediasMoviles &mas) {
    
    ContadorIDSeñales++;
    
    tracking.id = ContadorIDSeñales;
    tracking.timestamp_entrada = Time[1];
    tracking.tipo = tipo;
    tracking.combinacion = combinacion;
    tracking.precio_entrada = Close[1];
    tracking.pips_actual = 0;
    tracking.pips_maximo = 0;
    tracking.pips_minimo = 0;
    tracking.precio_maximo = Close[1];
    tracking.precio_minimo = Close[1];
    tracking.timestamp_maximo = Time[1];
    tracking.bars_duracion = 0;
    tracking.activo = true;
    tracking.todas_salidas_cerradas = false;
    
    MqlDateTime dt;
    TimeToStruct(Time[1], dt);
    tracking.hora_entrada = dt.hour;
    tracking.dia_semana_entrada = dt.day_of_week;
    
    tracking.ma200_entry = mas.ma200_close;
    tracking.ma220_entry = mas.ma220_open;
    tracking.ma100_entry = mas.ma100_close;
    tracking.ma105_entry = mas.ma105_open;
    tracking.ma50_entry = mas.ma50_close;
    tracking.ma53_entry = mas.ma53_open;
    tracking.ma20_entry = mas.ma20_close;
    tracking.ma22_entry = mas.ma22_open;
    tracking.ma5_entry = mas.ma5_close;
    
    // Inicializar salidas pips
    InicializarSalida(tracking.salida_pips_5_info);
    InicializarSalida(tracking.salida_pips_10_info);
    InicializarSalida(tracking.salida_pips_15_info);
    InicializarSalida(tracking.salida_pips_20_info);
    InicializarSalida(tracking.salida_pips_25_info);
    InicializarSalida(tracking.salida_pips_30_info);
    InicializarSalida(tracking.salida_pips_35_info);
    InicializarSalida(tracking.salida_pips_40_info);
    InicializarSalida(tracking.salida_pips_50_info);
    InicializarSalida(tracking.salida_pips_55_info);
    InicializarSalida(tracking.salida_pips_60_info);
    InicializarSalida(tracking.salida_pips_65_info);
    InicializarSalida(tracking.salida_pips_70_info);
    InicializarSalida(tracking.salida_pips_75_info);
    InicializarSalida(tracking.salida_pips_80_info);
    InicializarSalida(tracking.salida_pips_85_info);
    InicializarSalida(tracking.salida_pips_90_info);
    InicializarSalida(tracking.salida_pips_100_info);
    InicializarSalida(tracking.salida_pips_plus100_info);
    
    // Inicializar salidas retroceso
    InicializarSalida(tracking.salida_retroceso_20_info);
    InicializarSalida(tracking.salida_retroceso_25_info);
    InicializarSalida(tracking.salida_retroceso_30_info);
    InicializarSalida(tracking.salida_retroceso_35_info);
    InicializarSalida(tracking.salida_retroceso_40_info);
    InicializarSalida(tracking.salida_retroceso_45_info);
    InicializarSalida(tracking.salida_retroceso_50_info);
    
    // Inicializar salidas cruces
    InicializarSalida(tracking.salida_cruce_a_info);
    InicializarSalida(tracking.salida_cruce_b_info);
    InicializarSalida(tracking.salida_cruce_c_info);
    InicializarSalida(tracking.salida_cruce_d_info);
    InicializarSalida(tracking.salida_cruce_e_info);
    
    // Inicializar salidas timeout
    InicializarSalida(tracking.salida_timeout_25_info);
    InicializarSalida(tracking.salida_timeout_50_info);
    InicializarSalida(tracking.salida_timeout_75_info);
    InicializarSalida(tracking.salida_timeout_100_info);
    InicializarSalida(tracking.salida_timeout_125_info);
    InicializarSalida(tracking.salida_timeout_150_info);
    InicializarSalida(tracking.salida_timeout_175_info);
    InicializarSalida(tracking.salida_timeout_200_info);
    InicializarSalida(tracking.salida_timeout_225_info);
    InicializarSalida(tracking.salida_timeout_250_info);
    InicializarSalida(tracking.salida_timeout_275_info);
    InicializarSalida(tracking.salida_timeout_300_info);
    InicializarSalida(tracking.salida_timeout_325_info);
    InicializarSalida(tracking.salida_timeout_350_info);
    InicializarSalida(tracking.salida_timeout_400_info);
    InicializarSalida(tracking.salida_timeout_450_info);
    InicializarSalida(tracking.salida_timeout_500_info);
    
    // Inicializar salidas StopLoss
    InicializarSalida(tracking.salida_sl_5_info);
    InicializarSalida(tracking.salida_sl_10_info);
    InicializarSalida(tracking.salida_sl_20_info);
    InicializarSalida(tracking.salida_sl_30_info);
    InicializarSalida(tracking.salida_sl_40_info);
    InicializarSalida(tracking.salida_sl_50_info);
    InicializarSalida(tracking.salida_sl_60_info);
    InicializarSalida(tracking.salida_sl_70_info);
    InicializarSalida(tracking.salida_sl_80_info);
    InicializarSalida(tracking.salida_sl_90_info);
    InicializarSalida(tracking.salida_sl_100_info);
    InicializarSalida(tracking.salida_sl_120_info);
    InicializarSalida(tracking.salida_sl_130_info);
    InicializarSalida(tracking.salida_sl_140_info);
    InicializarSalida(tracking.salida_sl_150_info);
    InicializarSalida(tracking.salida_sl_160_info);
    InicializarSalida(tracking.salida_sl_170_info);
    InicializarSalida(tracking.salida_sl_180_info);
    InicializarSalida(tracking.salida_sl_190_info);
    InicializarSalida(tracking.salida_sl_200_info);
    
    // Inicializar salida señal contraria
    InicializarSalida(tracking.salida_senal_contraria_info);
    
    TotalTradesActivos++;
}

//+------------------------------------------------------------------+
//| Inicializar estructura de salida                                  |
//+------------------------------------------------------------------+
void InicializarSalida(InfoSalida &salida) {
    salida.cerrada = false;
    salida.timestamp = 0;
    salida.precio = 0;
    salida.pips = 0;
    salida.bars = 0;
}

//+------------------------------------------------------------------+
//| Registrar salida en estructura                                    |
//+------------------------------------------------------------------+
void RegistrarSalidaEnStruct(InfoSalida &salida, TradeVirtual &tracking) {
    if(!salida.cerrada) {
        salida.cerrada = true;
        salida.timestamp = Time[0];
        salida.precio = Close[0];
        salida.pips = tracking.pips_actual;
        salida.bars = tracking.bars_duracion;
    }
}

//+------------------------------------------------------------------+
//| Actualizar tracking virtual                                       |
//+------------------------------------------------------------------+
void ActualizarTrackingVirtual(TradeVirtual &tracking, MediasMoviles &mas) {
    if(!tracking.activo) return;
    
    tracking.bars_duracion++;
    
    double precio_actual = Close[0];
    double diferencia = 0;
    
    if(tracking.tipo == "BUY") {
        diferencia = precio_actual - tracking.precio_entrada;
    } else {
        diferencia = tracking.precio_entrada - precio_actual;
    }
    
    tracking.pips_actual = diferencia / PipValue;
    
    if(tracking.pips_actual > tracking.pips_maximo) {
        tracking.pips_maximo = tracking.pips_actual;
        tracking.precio_maximo = precio_actual;
        tracking.timestamp_maximo = Time[0];
    }
    if(tracking.pips_actual < tracking.pips_minimo) {
        tracking.pips_minimo = tracking.pips_actual;
        tracking.precio_minimo = precio_actual;
    }
    
    EvaluarSalidasPipsFijos(tracking);
    EvaluarSalidasRetroceso(tracking);
    EvaluarSalidasCruces(tracking, mas);
    EvaluarSalidasTimeouts(tracking);
    EvaluarSalidasStopLoss(tracking);
    EvaluarSalidaSeñalContraria(tracking, mas);
    
    // CORREGIDO v1.05: Solo cierra en timeout de 500 bars
    if(tracking.bars_duracion >= 500) {
        FinalizarTrackingVirtual(tracking, mas);
    }
}

//+------------------------------------------------------------------+
//| Evaluar salidas por pips fijos                                    |
//+------------------------------------------------------------------+
void EvaluarSalidasPipsFijos(TradeVirtual &tracking) {
    if(Salida_Pips_5 && !tracking.salida_pips_5_info.cerrada && tracking.pips_actual >= 5) {
        RegistrarSalidaEnStruct(tracking.salida_pips_5_info, tracking);
    }
    
    if(Salida_Pips_10 && !tracking.salida_pips_10_info.cerrada && tracking.pips_actual >= 10) {
        RegistrarSalidaEnStruct(tracking.salida_pips_10_info, tracking);
    }
    
    if(Salida_Pips_15 && !tracking.salida_pips_15_info.cerrada && tracking.pips_actual >= 15) {
        RegistrarSalidaEnStruct(tracking.salida_pips_15_info, tracking);
    }
    
    if(Salida_Pips_20 && !tracking.salida_pips_20_info.cerrada && tracking.pips_actual >= 20) {
        RegistrarSalidaEnStruct(tracking.salida_pips_20_info, tracking);
    }
    
    if(Salida_Pips_25 && !tracking.salida_pips_25_info.cerrada && tracking.pips_actual >= 25) {
        RegistrarSalidaEnStruct(tracking.salida_pips_25_info, tracking);
    }
    
    if(Salida_Pips_30 && !tracking.salida_pips_30_info.cerrada && tracking.pips_actual >= 30) {
        RegistrarSalidaEnStruct(tracking.salida_pips_30_info, tracking);
    }
    
    if(Salida_Pips_35 && !tracking.salida_pips_35_info.cerrada && tracking.pips_actual >= 35) {
        RegistrarSalidaEnStruct(tracking.salida_pips_35_info, tracking);
    }
    
    if(Salida_Pips_40 && !tracking.salida_pips_40_info.cerrada && tracking.pips_actual >= 40) {
        RegistrarSalidaEnStruct(tracking.salida_pips_40_info, tracking);
    }
    
    if(Salida_Pips_50 && !tracking.salida_pips_50_info.cerrada && tracking.pips_actual >= 50) {
        RegistrarSalidaEnStruct(tracking.salida_pips_50_info, tracking);
    }
    
    if(Salida_Pips_55 && !tracking.salida_pips_55_info.cerrada && tracking.pips_actual >= 55) {
        RegistrarSalidaEnStruct(tracking.salida_pips_55_info, tracking);
    }
    
    if(Salida_Pips_60 && !tracking.salida_pips_60_info.cerrada && tracking.pips_actual >= 60) {
        RegistrarSalidaEnStruct(tracking.salida_pips_60_info, tracking);
    }
    
    if(Salida_Pips_65 && !tracking.salida_pips_65_info.cerrada && tracking.pips_actual >= 65) {
        RegistrarSalidaEnStruct(tracking.salida_pips_65_info, tracking);
    }
    
    if(Salida_Pips_70 && !tracking.salida_pips_70_info.cerrada && tracking.pips_actual >= 70) {
        RegistrarSalidaEnStruct(tracking.salida_pips_70_info, tracking);
    }
    
    if(Salida_Pips_75 && !tracking.salida_pips_75_info.cerrada && tracking.pips_actual >= 75) {
        RegistrarSalidaEnStruct(tracking.salida_pips_75_info, tracking);
    }
    
    if(Salida_Pips_80 && !tracking.salida_pips_80_info.cerrada && tracking.pips_actual >= 80) {
        RegistrarSalidaEnStruct(tracking.salida_pips_80_info, tracking);
    }
    
    if(Salida_Pips_85 && !tracking.salida_pips_85_info.cerrada && tracking.pips_actual >= 85) {
        RegistrarSalidaEnStruct(tracking.salida_pips_85_info, tracking);
    }
    
    if(Salida_Pips_90 && !tracking.salida_pips_90_info.cerrada && tracking.pips_actual >= 90) {
        RegistrarSalidaEnStruct(tracking.salida_pips_90_info, tracking);
    }
    
    if(Salida_Pips_100 && !tracking.salida_pips_100_info.cerrada && tracking.pips_actual >= 100) {
        RegistrarSalidaEnStruct(tracking.salida_pips_100_info, tracking);
    }
    
    if(Salida_Pips_Plus100 && !tracking.salida_pips_plus100_info.cerrada && tracking.pips_actual > 100) {
        RegistrarSalidaEnStruct(tracking.salida_pips_plus100_info, tracking);
    }
}

//+------------------------------------------------------------------+
//| Evaluar salidas por retroceso                                     |
//+------------------------------------------------------------------+
void EvaluarSalidasRetroceso(TradeVirtual &tracking) {
    if(tracking.pips_maximo < UmbralMinimoPips) return;
    
    double retroceso_pct = ((tracking.pips_maximo - tracking.pips_actual) / tracking.pips_maximo) * 100;
    
    if(Salida_Retroceso_20 && !tracking.salida_retroceso_20_info.cerrada && retroceso_pct >= 20) {
        RegistrarSalidaEnStruct(tracking.salida_retroceso_20_info, tracking);
    }
    
    if(Salida_Retroceso_25 && !tracking.salida_retroceso_25_info.cerrada && retroceso_pct >= 25) {
        RegistrarSalidaEnStruct(tracking.salida_retroceso_25_info, tracking);
    }
    
    if(Salida_Retroceso_30 && !tracking.salida_retroceso_30_info.cerrada && retroceso_pct >= 30) {
        RegistrarSalidaEnStruct(tracking.salida_retroceso_30_info, tracking);
    }
    
    if(Salida_Retroceso_35 && !tracking.salida_retroceso_35_info.cerrada && retroceso_pct >= 35) {
        RegistrarSalidaEnStruct(tracking.salida_retroceso_35_info, tracking);
    }
    
    if(Salida_Retroceso_40 && !tracking.salida_retroceso_40_info.cerrada && retroceso_pct >= 40) {
        RegistrarSalidaEnStruct(tracking.salida_retroceso_40_info, tracking);
    }
    
    if(Salida_Retroceso_45 && !tracking.salida_retroceso_45_info.cerrada && retroceso_pct >= 45) {
        RegistrarSalidaEnStruct(tracking.salida_retroceso_45_info, tracking);
    }
    
    if(Salida_Retroceso_50 && !tracking.salida_retroceso_50_info.cerrada && retroceso_pct >= 50) {
        RegistrarSalidaEnStruct(tracking.salida_retroceso_50_info, tracking);
    }
}

//+------------------------------------------------------------------+
//| Evaluar salidas por cruces - 5 salidas                            |
//+------------------------------------------------------------------+
void EvaluarSalidasCruces(TradeVirtual &tracking, MediasMoviles &mas) {
    // Cruce_a: LWMA200 vs LWMA220
    if(Salida_Cruce_a && !tracking.salida_cruce_a_info.cerrada) {
        bool cruce_inverso = false;
        if(tracking.tipo == "BUY") {
            cruce_inverso = (mas.ma200_close < mas.ma220_open);
        } else {
            cruce_inverso = (mas.ma200_close > mas.ma220_open);
        }
        
        if(cruce_inverso) {
            RegistrarSalidaEnStruct(tracking.salida_cruce_a_info, tracking);
        }
    }
    
    // Cruce_b: LWMA100 vs LWMA105
    if(Salida_Cruce_b && !tracking.salida_cruce_b_info.cerrada) {
        bool cruce_inverso = false;
        if(tracking.tipo == "BUY") {
            cruce_inverso = (mas.ma100_close < mas.ma105_open);
        } else {
            cruce_inverso = (mas.ma100_close > mas.ma105_open);
        }
        
        if(cruce_inverso) {
            RegistrarSalidaEnStruct(tracking.salida_cruce_b_info, tracking);
        }
    }
    
    // Cruce_c: LWMA50 vs LWMA53
    if(Salida_Cruce_c && !tracking.salida_cruce_c_info.cerrada) {
        bool cruce_inverso = false;
        if(tracking.tipo == "BUY") {
            cruce_inverso = (mas.ma50_close < mas.ma53_open);
        } else {
            cruce_inverso = (mas.ma50_close > mas.ma53_open);
        }
        
        if(cruce_inverso) {
            RegistrarSalidaEnStruct(tracking.salida_cruce_c_info, tracking);
        }
    }
    
    // Cruce_d: LWMA20 vs LWMA22
    if(Salida_Cruce_d && !tracking.salida_cruce_d_info.cerrada) {
        bool cruce_inverso = false;
        if(tracking.tipo == "BUY") {
            cruce_inverso = (mas.ma20_close < mas.ma22_open);
        } else {
            cruce_inverso = (mas.ma20_close > mas.ma22_open);
        }
        
        if(cruce_inverso) {
            RegistrarSalidaEnStruct(tracking.salida_cruce_d_info, tracking);
        }
    }
    
    if(Salida_Cruce_c && !tracking.salida_cruce_c_info.cerrada) {
        bool cruce_inverso = false;
        if(tracking.tipo == "BUY") {
            cruce_inverso = (mas.ma50_close < mas.ma53_open);
        } else {
            cruce_inverso = (mas.ma50_close > mas.ma53_open);
        }
        
        if(cruce_inverso) {
            RegistrarSalidaEnStruct(tracking.salida_cruce_c_info, tracking);
        }
    }
    
    if(Salida_Cruce_b && !tracking.salida_cruce_b_info.cerrada) {
        bool cruce_inverso = false;
        if(tracking.tipo == "BUY") {
            cruce_inverso = (mas.ma100_close < mas.ma105_open);
        } else {
            cruce_inverso = (mas.ma100_close > mas.ma105_open);
        }
        
        if(cruce_inverso) {
            RegistrarSalidaEnStruct(tracking.salida_cruce_b_info, tracking);
        }
    }
    
    // Cruce_e: Precio vs SMA5
    if(Salida_Cruce_e && !tracking.salida_cruce_e_info.cerrada) {
        bool cruce_inverso = false;
        if(tracking.tipo == "BUY") {
            cruce_inverso = (Close[0] < mas.ma5_close);
        } else {
            cruce_inverso = (Close[0] > mas.ma5_close);
        }
        
        if(cruce_inverso) {
            RegistrarSalidaEnStruct(tracking.salida_cruce_e_info, tracking);
        }
    }
}

//+------------------------------------------------------------------+
//| Evaluar salidas por timeouts - 17 salidas                         |
//+------------------------------------------------------------------+
void EvaluarSalidasTimeouts(TradeVirtual &tracking) {
    if(tracking.bars_duracion == 25 && !tracking.salida_timeout_25_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_25_info, tracking);
    }
    
    if(tracking.bars_duracion == 50 && !tracking.salida_timeout_50_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_50_info, tracking);
    }
    
    if(tracking.bars_duracion == 75 && !tracking.salida_timeout_75_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_75_info, tracking);
    }
    
    if(tracking.bars_duracion == 100 && !tracking.salida_timeout_100_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_100_info, tracking);
    }
    
    if(tracking.bars_duracion == 125 && !tracking.salida_timeout_125_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_125_info, tracking);
    }
    
    if(tracking.bars_duracion == 150 && !tracking.salida_timeout_150_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_150_info, tracking);
    }
    
    if(tracking.bars_duracion == 175 && !tracking.salida_timeout_175_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_175_info, tracking);
    }
    
    if(tracking.bars_duracion == 200 && !tracking.salida_timeout_200_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_200_info, tracking);
    }
    
    if(tracking.bars_duracion == 225 && !tracking.salida_timeout_225_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_225_info, tracking);
    }
    
    if(tracking.bars_duracion == 250 && !tracking.salida_timeout_250_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_250_info, tracking);
    }
    
    if(tracking.bars_duracion == 275 && !tracking.salida_timeout_275_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_275_info, tracking);
    }
    
    if(tracking.bars_duracion == 300 && !tracking.salida_timeout_300_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_300_info, tracking);
    }
    
    if(tracking.bars_duracion == 325 && !tracking.salida_timeout_325_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_325_info, tracking);
    }
    
    if(tracking.bars_duracion == 350 && !tracking.salida_timeout_350_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_350_info, tracking);
    }
    
    if(tracking.bars_duracion == 400 && !tracking.salida_timeout_400_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_400_info, tracking);
    }
    
    if(tracking.bars_duracion == 450 && !tracking.salida_timeout_450_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_450_info, tracking);
    }
    
    if(tracking.bars_duracion == 500 && !tracking.salida_timeout_500_info.cerrada) {
        RegistrarSalidaEnStruct(tracking.salida_timeout_500_info, tracking);
    }
}

//+------------------------------------------------------------------+
//| Evaluar salidas StopLoss - 20 salidas - NUEVO v1.05               |
//+------------------------------------------------------------------+
void EvaluarSalidasStopLoss(TradeVirtual &tracking) {
    if(!tracking.salida_sl_5_info.cerrada && tracking.pips_actual <= -5) {
        RegistrarSalidaEnStruct(tracking.salida_sl_5_info, tracking);
    }
    
    if(!tracking.salida_sl_10_info.cerrada && tracking.pips_actual <= -10) {
        RegistrarSalidaEnStruct(tracking.salida_sl_10_info, tracking);
    }
    
    if(!tracking.salida_sl_20_info.cerrada && tracking.pips_actual <= -20) {
        RegistrarSalidaEnStruct(tracking.salida_sl_20_info, tracking);
    }
    
    if(!tracking.salida_sl_30_info.cerrada && tracking.pips_actual <= -30) {
        RegistrarSalidaEnStruct(tracking.salida_sl_30_info, tracking);
    }
    
    if(!tracking.salida_sl_40_info.cerrada && tracking.pips_actual <= -40) {
        RegistrarSalidaEnStruct(tracking.salida_sl_40_info, tracking);
    }
    
    if(!tracking.salida_sl_50_info.cerrada && tracking.pips_actual <= -50) {
        RegistrarSalidaEnStruct(tracking.salida_sl_50_info, tracking);
    }
    
    if(!tracking.salida_sl_60_info.cerrada && tracking.pips_actual <= -60) {
        RegistrarSalidaEnStruct(tracking.salida_sl_60_info, tracking);
    }
    
    if(!tracking.salida_sl_70_info.cerrada && tracking.pips_actual <= -70) {
        RegistrarSalidaEnStruct(tracking.salida_sl_70_info, tracking);
    }
    
    if(!tracking.salida_sl_80_info.cerrada && tracking.pips_actual <= -80) {
        RegistrarSalidaEnStruct(tracking.salida_sl_80_info, tracking);
    }
    
    if(!tracking.salida_sl_90_info.cerrada && tracking.pips_actual <= -90) {
        RegistrarSalidaEnStruct(tracking.salida_sl_90_info, tracking);
    }
    
    if(!tracking.salida_sl_100_info.cerrada && tracking.pips_actual <= -100) {
        RegistrarSalidaEnStruct(tracking.salida_sl_100_info, tracking);
    }
    
    if(!tracking.salida_sl_120_info.cerrada && tracking.pips_actual <= -120) {
        RegistrarSalidaEnStruct(tracking.salida_sl_120_info, tracking);
    }
    
    if(!tracking.salida_sl_130_info.cerrada && tracking.pips_actual <= -130) {
        RegistrarSalidaEnStruct(tracking.salida_sl_130_info, tracking);
    }
    
    if(!tracking.salida_sl_140_info.cerrada && tracking.pips_actual <= -140) {
        RegistrarSalidaEnStruct(tracking.salida_sl_140_info, tracking);
    }
    
    if(!tracking.salida_sl_150_info.cerrada && tracking.pips_actual <= -150) {
        RegistrarSalidaEnStruct(tracking.salida_sl_150_info, tracking);
    }
    
    if(!tracking.salida_sl_160_info.cerrada && tracking.pips_actual <= -160) {
        RegistrarSalidaEnStruct(tracking.salida_sl_160_info, tracking);
    }
    
    if(!tracking.salida_sl_170_info.cerrada && tracking.pips_actual <= -170) {
        RegistrarSalidaEnStruct(tracking.salida_sl_170_info, tracking);
    }
    
    if(!tracking.salida_sl_180_info.cerrada && tracking.pips_actual <= -180) {
        RegistrarSalidaEnStruct(tracking.salida_sl_180_info, tracking);
    }
    
    if(!tracking.salida_sl_190_info.cerrada && tracking.pips_actual <= -190) {
        RegistrarSalidaEnStruct(tracking.salida_sl_190_info, tracking);
    }
    
    if(!tracking.salida_sl_200_info.cerrada && tracking.pips_actual <= -200) {
        RegistrarSalidaEnStruct(tracking.salida_sl_200_info, tracking);
    }
}

//+------------------------------------------------------------------+
//| Evaluar salida por señal contraria - NUEVO v1.05                  |
//+------------------------------------------------------------------+
void EvaluarSalidaSeñalContraria(TradeVirtual &tracking, MediasMoviles &mas) {
    if(tracking.salida_senal_contraria_info.cerrada) return;
    
    bool señal_contraria = false;
    
    // Detectar si aparece señal contraria según la combinación del trade
    if(tracking.combinacion == "A") {
        // A = a+b+c+d
        if(tracking.tipo == "BUY") {
            bool cond_a_sell = EvaluarCondicion_a_Inversa(mas);
            bool cond_b_sell = EvaluarCondicion_b_Inversa(mas);
            bool cond_c_sell = EvaluarCondicion_c_Inversa(mas);
            bool cond_d_sell = EvaluarCondicion_d_Inversa(mas);
            señal_contraria = cond_a_sell && cond_b_sell && cond_c_sell && cond_d_sell;
        } else {
            bool cond_a_buy = EvaluarCondicion_a(mas);
            bool cond_b_buy = EvaluarCondicion_b(mas);
            bool cond_c_buy = EvaluarCondicion_c(mas);
            bool cond_d_buy = EvaluarCondicion_d(mas);
            señal_contraria = cond_a_buy && cond_b_buy && cond_c_buy && cond_d_buy;
        }
    }
    else if(tracking.combinacion == "B") {
        // B = a+b+c
        if(tracking.tipo == "BUY") {
            bool cond_a_sell = EvaluarCondicion_a_Inversa(mas);
            bool cond_b_sell = EvaluarCondicion_b_Inversa(mas);
            bool cond_c_sell = EvaluarCondicion_c_Inversa(mas);
            señal_contraria = cond_a_sell && cond_b_sell && cond_c_sell;
        } else {
            bool cond_a_buy = EvaluarCondicion_a(mas);
            bool cond_b_buy = EvaluarCondicion_b(mas);
            bool cond_c_buy = EvaluarCondicion_c(mas);
            señal_contraria = cond_a_buy && cond_b_buy && cond_c_buy;
        }
    }
    else if(tracking.combinacion == "C") {
        // C = a+b+d
        if(tracking.tipo == "BUY") {
            bool cond_a_sell = EvaluarCondicion_a_Inversa(mas);
            bool cond_b_sell = EvaluarCondicion_b_Inversa(mas);
            bool cond_d_sell = EvaluarCondicion_d_Inversa(mas);
            señal_contraria = cond_a_sell && cond_b_sell && cond_d_sell;
        } else {
            bool cond_a_buy = EvaluarCondicion_a(mas);
            bool cond_b_buy = EvaluarCondicion_b(mas);
            bool cond_d_buy = EvaluarCondicion_d(mas);
            señal_contraria = cond_a_buy && cond_b_buy && cond_d_buy;
        }
    }
    else if(tracking.combinacion == "D") {
        // D = a+c+d
        if(tracking.tipo == "BUY") {
            bool cond_a_sell = EvaluarCondicion_a_Inversa(mas);
            bool cond_c_sell = EvaluarCondicion_c_Inversa(mas);
            bool cond_d_sell = EvaluarCondicion_d_Inversa(mas);
            señal_contraria = cond_a_sell && cond_c_sell && cond_d_sell;
        } else {
            bool cond_a_buy = EvaluarCondicion_a(mas);
            bool cond_c_buy = EvaluarCondicion_c(mas);
            bool cond_d_buy = EvaluarCondicion_d(mas);
            señal_contraria = cond_a_buy && cond_c_buy && cond_d_buy;
        }
    }
    else if(tracking.combinacion == "E") {
        // E = a+d+e
        if(tracking.tipo == "BUY") {
            bool cond_a_sell = EvaluarCondicion_a_Inversa(mas);
            bool cond_d_sell = EvaluarCondicion_d_Inversa(mas);
            bool cond_e_sell = EvaluarCondicion_e_Inversa(mas);
            señal_contraria = cond_a_sell && cond_d_sell && cond_e_sell;
        } else {
            bool cond_a_buy = EvaluarCondicion_a(mas);
            bool cond_d_buy = EvaluarCondicion_d(mas);
            bool cond_e_buy = EvaluarCondicion_e(mas);
            señal_contraria = cond_a_buy && cond_d_buy && cond_e_buy;
        }
    }
    
    if(señal_contraria) {
        RegistrarSalidaEnStruct(tracking.salida_senal_contraria_info, tracking);
        
        if(LoggingDetallado) {
            Print("SEÑAL CONTRARIA DETECTADA - ", tracking.tipo, " Combinación ", tracking.combinacion,
                  " | Pips: ", DoubleToString(tracking.pips_actual, 2),
                  " | Bars: ", tracking.bars_duracion);
        }
    }
}

//+------------------------------------------------------------------+
//| Finalizar tracking y registrar resumen completo                   |
//+------------------------------------------------------------------+
void FinalizarTrackingVirtual(TradeVirtual &tracking, MediasMoviles &mas) {
    tracking.ma200_exit = mas.ma200_close;
    tracking.ma220_exit = mas.ma220_open;
    tracking.ma100_exit = mas.ma100_close;
    tracking.ma105_exit = mas.ma105_open;
    tracking.ma50_exit = mas.ma50_close;
    tracking.ma53_exit = mas.ma53_open;
    tracking.ma20_exit = mas.ma20_close;
    tracking.ma22_exit = mas.ma22_open;
    tracking.ma5_exit = mas.ma5_close;
    
    if(ExportarCSV) {
        RegistrarResumenCompleto(tracking);
    }
    
    tracking.activo = false;
    tracking.todas_salidas_cerradas = true;
    TotalTradesActivos--;
    
    if(LoggingDetallado) {
        Print("FINALIZADO - ", tracking.tipo, " Combinación ", tracking.combinacion,
              " | Pips Máximo: ", DoubleToString(tracking.pips_maximo, 2),
              " | Pips Mínimo: ", DoubleToString(tracking.pips_minimo, 2),
              " | Duración: ", tracking.bars_duracion, " bars");
    }
}

//+------------------------------------------------------------------+
//| Registrar señal detallada                                         |
//+------------------------------------------------------------------+
void RegistrarSeñalDetallada(string tipo, string combinacion, MediasMoviles &mas,
                             bool tracking_iniciado, string razon_no_iniciado,
                             bool cond_a, bool cond_b, bool cond_c, bool cond_d, bool cond_e) {
    if(FileHandleSeñales < 0) return;
    
    MqlDateTime dt;
    TimeToStruct(Time[1], dt);
    
    string linea = TimeToString(Time[1], TIME_DATE|TIME_MINUTES) + "," +
                   PeriodToString(Period()) + "," +
                   tipo + "," +
                   combinacion + "," +
                   DoubleToString(Close[1], SimboloDigits) + "," +
                   (cond_a ? "1" : "0") + "," +
                   (cond_b ? "1" : "0") + "," +
                   (cond_c ? "1" : "0") + "," +
                   (cond_d ? "1" : "0") + "," +
                   (cond_e ? "1" : "0") + "," +
                   IntegerToString(dt.hour) + "," +
                   IntegerToString(dt.day_of_week) + "," +
                   (tracking_iniciado ? "SI" : "NO") + "," +
                   razon_no_iniciado + "," +
                   DoubleToString(mas.ma200_close, SimboloDigits) + "," +
                   DoubleToString(mas.ma220_open, SimboloDigits) + "," +
                   DoubleToString(mas.ma100_close, SimboloDigits) + "," +
                   DoubleToString(mas.ma105_open, SimboloDigits) + "," +
                   DoubleToString(mas.ma50_close, SimboloDigits) + "," +
                   DoubleToString(mas.ma53_open, SimboloDigits) + "," +
                   DoubleToString(mas.ma20_close, SimboloDigits) + "," +
                   DoubleToString(mas.ma22_open, SimboloDigits) + "," +
                   DoubleToString(mas.ma5_close, SimboloDigits) + "\r\n";
    
    FileWriteString(FileHandleSeñales, linea);
}

//+------------------------------------------------------------------+
//| Registrar resumen completo en formato WIDE                        |
//+------------------------------------------------------------------+
void RegistrarResumenCompleto(TradeVirtual &tracking) {
    if(FileHandleResumen < 0) return;
    
    string linea = IntegerToString(tracking.id) + "," +
                   TimeToString(tracking.timestamp_entrada, TIME_DATE|TIME_MINUTES) + "," +
                   tracking.tipo + "," +
                   tracking.combinacion + "," +
                   DoubleToString(tracking.precio_entrada, SimboloDigits) + "," +
                   IntegerToString(tracking.hora_entrada) + "," +
                   IntegerToString(tracking.dia_semana_entrada) + "," +
                   IntegerToString(tracking.bars_duracion) + "," +
                   DoubleToString(tracking.pips_maximo, 2) + "," +
                   DoubleToString(tracking.precio_maximo, SimboloDigits) + "," +
                   TimeToString(tracking.timestamp_maximo, TIME_DATE|TIME_MINUTES) + "," +
                   DoubleToString(tracking.pips_minimo, 2) + "," +
                   DoubleToString(tracking.precio_minimo, SimboloDigits) + "," +
                   
                   DoubleToString(tracking.ma200_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma220_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma100_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma105_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma50_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma53_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma20_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma22_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma5_entry, SimboloDigits) + "," +
                   
                   DoubleToString(tracking.ma200_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma220_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma100_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma105_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma50_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma53_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma20_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma22_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma5_exit, SimboloDigits) + "," +
                   
                   FormatearSalida(tracking.salida_pips_5_info) +
                   FormatearSalida(tracking.salida_pips_10_info) +
                   FormatearSalida(tracking.salida_pips_15_info) +
                   FormatearSalida(tracking.salida_pips_20_info) +
                   FormatearSalida(tracking.salida_pips_25_info) +
                   FormatearSalida(tracking.salida_pips_30_info) +
                   FormatearSalida(tracking.salida_pips_35_info) +
                   FormatearSalida(tracking.salida_pips_40_info) +
                   FormatearSalida(tracking.salida_pips_50_info) +
                   FormatearSalida(tracking.salida_pips_55_info) +
                   FormatearSalida(tracking.salida_pips_60_info) +
                   FormatearSalida(tracking.salida_pips_65_info) +
                   FormatearSalida(tracking.salida_pips_70_info) +
                   FormatearSalida(tracking.salida_pips_75_info) +
                   FormatearSalida(tracking.salida_pips_80_info) +
                   FormatearSalida(tracking.salida_pips_85_info) +
                   FormatearSalida(tracking.salida_pips_90_info) +
                   FormatearSalida(tracking.salida_pips_100_info) +
                   FormatearSalida(tracking.salida_pips_plus100_info) +
                   
                   FormatearSalida(tracking.salida_retroceso_20_info) +
                   FormatearSalida(tracking.salida_retroceso_25_info) +
                   FormatearSalida(tracking.salida_retroceso_30_info) +
                   FormatearSalida(tracking.salida_retroceso_35_info) +
                   FormatearSalida(tracking.salida_retroceso_40_info) +
                   FormatearSalida(tracking.salida_retroceso_45_info) +
                   FormatearSalida(tracking.salida_retroceso_50_info) +
                   
                   // Cruces (5)
                   FormatearSalida(tracking.salida_cruce_a_info) +
                   FormatearSalida(tracking.salida_cruce_b_info) +
                   FormatearSalida(tracking.salida_cruce_c_info) +
                   FormatearSalida(tracking.salida_cruce_d_info) +
                   FormatearSalida(tracking.salida_cruce_e_info) +
                   
                   FormatearSalida(tracking.salida_timeout_25_info) +
                   FormatearSalida(tracking.salida_timeout_50_info) +
                   FormatearSalida(tracking.salida_timeout_75_info) +
                   FormatearSalida(tracking.salida_timeout_100_info) +
                   FormatearSalida(tracking.salida_timeout_125_info) +
                   FormatearSalida(tracking.salida_timeout_150_info) +
                   FormatearSalida(tracking.salida_timeout_175_info) +
                   FormatearSalida(tracking.salida_timeout_200_info) +
                   FormatearSalida(tracking.salida_timeout_225_info) +
                   FormatearSalida(tracking.salida_timeout_250_info) +
                   FormatearSalida(tracking.salida_timeout_275_info) +
                   FormatearSalida(tracking.salida_timeout_300_info) +
                   FormatearSalida(tracking.salida_timeout_325_info) +
                   FormatearSalida(tracking.salida_timeout_350_info) +
                   FormatearSalida(tracking.salida_timeout_400_info) +
                   FormatearSalida(tracking.salida_timeout_450_info) +
                   FormatearSalida(tracking.salida_timeout_500_info) +
                   
                   // StopLoss (20)
                   FormatearSalida(tracking.salida_sl_5_info) +
                   FormatearSalida(tracking.salida_sl_10_info) +
                   FormatearSalida(tracking.salida_sl_20_info) +
                   FormatearSalida(tracking.salida_sl_30_info) +
                   FormatearSalida(tracking.salida_sl_40_info) +
                   FormatearSalida(tracking.salida_sl_50_info) +
                   FormatearSalida(tracking.salida_sl_60_info) +
                   FormatearSalida(tracking.salida_sl_70_info) +
                   FormatearSalida(tracking.salida_sl_80_info) +
                   FormatearSalida(tracking.salida_sl_90_info) +
                   FormatearSalida(tracking.salida_sl_100_info) +
                   FormatearSalida(tracking.salida_sl_120_info) +
                   FormatearSalida(tracking.salida_sl_130_info) +
                   FormatearSalida(tracking.salida_sl_140_info) +
                   FormatearSalida(tracking.salida_sl_150_info) +
                   FormatearSalida(tracking.salida_sl_160_info) +
                   FormatearSalida(tracking.salida_sl_170_info) +
                   FormatearSalida(tracking.salida_sl_180_info) +
                   FormatearSalida(tracking.salida_sl_190_info) +
                   FormatearSalida(tracking.salida_sl_200_info) +
                   
                   // Señal Contraria (1)
                   FormatearSalida(tracking.salida_senal_contraria_info, true) + "\r\n";
    
    BufferCSVResumen += linea;
    ContadorBufferResumen++;
    
    if(ContadorBufferResumen >= BufferCSV_Lineas) {
        FileWriteString(FileHandleResumen, BufferCSVResumen);
        FileFlush(FileHandleResumen);
        BufferCSVResumen = "";
        ContadorBufferResumen = 0;
    }
}

//+------------------------------------------------------------------+
//| Formatear información de salida para CSV                          |
//+------------------------------------------------------------------+
string FormatearSalida(InfoSalida &salida, bool es_ultimo = false) {
    string separador = es_ultimo ? "" : ",";
    
    if(!salida.cerrada) {
        return "NA,NA,NA,NA" + separador;
    }
    
    return TimeToString(salida.timestamp, TIME_DATE|TIME_MINUTES) + "," +
           DoubleToString(salida.precio, SimboloDigits) + "," +
           DoubleToString(salida.pips, 2) + "," +
           IntegerToString(salida.bars) + separador;
}

//+------------------------------------------------------------------+
//| Inicializar archivos CSV                                          |
//+------------------------------------------------------------------+
bool InicializarArchivosCSV() {
    string fecha = TimeToString(TimeCurrent(), TIME_DATE);
    StringReplace(fecha, ".", "_");
    string timeframe_str = PeriodToString(Period());
    
    string nombre_señales = "MAs_Señales_" + SimboloActual + "_" + timeframe_str + "_" + fecha + ".csv";
    FileHandleSeñales = FileOpen(nombre_señales, FILE_WRITE|FILE_ANSI, ",");
    
    if(FileHandleSeñales >= 0) {
        string header = "Timestamp,Timeframe,Tipo,Combinacion,Precio,Cond_a,Cond_b,Cond_c,Cond_d,Cond_e,Hora,Dia_Semana,Tracking_Iniciado,Razon_No_Iniciado,MA200,MA220,MA100,MA105,MA50,MA53,MA20,MA22,MA5\r\n";
        FileWriteString(FileHandleSeñales, header);
        Print("Archivo señales creado: ", nombre_señales);
    } else {
        Print("ERROR: No se pudo crear archivo de señales");
        return false;
    }
    
    string nombre_resumen = "MAs_Resumen_" + SimboloActual + "_" + timeframe_str + "_" + fecha + ".csv";
    FileHandleResumen = FileOpen(nombre_resumen, FILE_WRITE|FILE_ANSI, ",");
    
    if(FileHandleResumen >= 0) {
        string header = "ID,Timestamp_Entrada,Tipo,Combinacion,Precio_Entrada,Hora_Entrada,Dia_Semana,Bars_Total,Pips_Maximo,Precio_Maximo,Timestamp_Maximo,Pips_Minimo,Precio_Minimo,";
        header += "MA200_Entry,MA220_Entry,MA100_Entry,MA105_Entry,MA50_Entry,MA53_Entry,MA20_Entry,MA22_Entry,MA5_Entry,";
        header += "MA200_Exit,MA220_Exit,MA100_Exit,MA105_Exit,MA50_Exit,MA53_Exit,MA20_Exit,MA22_Exit,MA5_Exit,";
        header += "P5_Time,P5_Precio,P5_Pips,P5_Bars,";
        header += "P10_Time,P10_Precio,P10_Pips,P10_Bars,";
        header += "P15_Time,P15_Precio,P15_Pips,P15_Bars,";
        header += "P20_Time,P20_Precio,P20_Pips,P20_Bars,";
        header += "P25_Time,P25_Precio,P25_Pips,P25_Bars,";
        header += "P30_Time,P30_Precio,P30_Pips,P30_Bars,";
        header += "P35_Time,P35_Precio,P35_Pips,P35_Bars,";
        header += "P40_Time,P40_Precio,P40_Pips,P40_Bars,";
        header += "P50_Time,P50_Precio,P50_Pips,P50_Bars,";
        header += "P55_Time,P55_Precio,P55_Pips,P55_Bars,";
        header += "P60_Time,P60_Precio,P60_Pips,P60_Bars,";
        header += "P65_Time,P65_Precio,P65_Pips,P65_Bars,";
        header += "P70_Time,P70_Precio,P70_Pips,P70_Bars,";
        header += "P75_Time,P75_Precio,P75_Pips,P75_Bars,";
        header += "P80_Time,P80_Precio,P80_Pips,P80_Bars,";
        header += "P85_Time,P85_Precio,P85_Pips,P85_Bars,";
        header += "P90_Time,P90_Precio,P90_Pips,P90_Bars,";
        header += "P100_Time,P100_Precio,P100_Pips,P100_Bars,";
        header += "P100plus_Time,P100plus_Precio,P100plus_Pips,P100plus_Bars,";
        
        // Retrocesos (7)
        header += "R20_Time,R20_Precio,R20_Pips,R20_Bars,";
        header += "R25_Time,R25_Precio,R25_Pips,R25_Bars,";
        header += "R30_Time,R30_Precio,R30_Pips,R30_Bars,";
        header += "R35_Time,R35_Precio,R35_Pips,R35_Bars,";
        header += "R40_Time,R40_Precio,R40_Pips,R40_Bars,";
        header += "R45_Time,R45_Precio,R45_Pips,R45_Bars,";
        header += "R50_Time,R50_Precio,R50_Pips,R50_Bars,";
        
        // Cruces (5)
        header += "Cruce_a_Time,Cruce_a_Precio,Cruce_a_Pips,Cruce_a_Bars,";
        header += "Cruce_b_Time,Cruce_b_Precio,Cruce_b_Pips,Cruce_b_Bars,";
        header += "Cruce_c_Time,Cruce_c_Precio,Cruce_c_Pips,Cruce_c_Bars,";
        header += "Cruce_d_Time,Cruce_d_Precio,Cruce_d_Pips,Cruce_d_Bars,";
        header += "Cruce_e_Time,Cruce_e_Precio,Cruce_e_Pips,Cruce_e_Bars,";
        
        // Timeouts (17)
        header += "T25_Time,T25_Precio,T25_Pips,T25_Bars,";
        header += "T50_Time,T50_Precio,T50_Pips,T50_Bars,";
        header += "T75_Time,T75_Precio,T75_Pips,T75_Bars,";
        header += "T100_Time,T100_Precio,T100_Pips,T100_Bars,";
        header += "T125_Time,T125_Precio,T125_Pips,T125_Bars,";
        header += "T150_Time,T150_Precio,T150_Pips,T150_Bars,";
        header += "T175_Time,T175_Precio,T175_Pips,T175_Bars,";
        header += "T200_Time,T200_Precio,T200_Pips,T200_Bars,";
        header += "T225_Time,T225_Precio,T225_Pips,T225_Bars,";
        header += "T250_Time,T250_Precio,T250_Pips,T250_Bars,";
        header += "T275_Time,T275_Precio,T275_Pips,T275_Bars,";
        header += "T300_Time,T300_Precio,T300_Pips,T300_Bars,";
        header += "T325_Time,T325_Precio,T325_Pips,T325_Bars,";
        header += "T350_Time,T350_Precio,T350_Pips,T350_Bars,";
        header += "T400_Time,T400_Precio,T400_Pips,T400_Bars,";
        header += "T450_Time,T450_Precio,T450_Pips,T450_Bars,";
        header += "T500_Time,T500_Precio,T500_Pips,T500_Bars,";
        
        // StopLoss (20)
        header += "SL5_Time,SL5_Precio,SL5_Pips,SL5_Bars,";
        header += "SL10_Time,SL10_Precio,SL10_Pips,SL10_Bars,";
        header += "SL20_Time,SL20_Precio,SL20_Pips,SL20_Bars,";
        header += "SL30_Time,SL30_Precio,SL30_Pips,SL30_Bars,";
        header += "SL40_Time,SL40_Precio,SL40_Pips,SL40_Bars,";
        header += "SL50_Time,SL50_Precio,SL50_Pips,SL50_Bars,";
        header += "SL60_Time,SL60_Precio,SL60_Pips,SL60_Bars,";
        header += "SL70_Time,SL70_Precio,SL70_Pips,SL70_Bars,";
        header += "SL80_Time,SL80_Precio,SL80_Pips,SL80_Bars,";
        header += "SL90_Time,SL90_Precio,SL90_Pips,SL90_Bars,";
        header += "SL100_Time,SL100_Precio,SL100_Pips,SL100_Bars,";
        header += "SL120_Time,SL120_Precio,SL120_Pips,SL120_Bars,";
        header += "SL130_Time,SL130_Precio,SL130_Pips,SL130_Bars,";
        header += "SL140_Time,SL140_Precio,SL140_Pips,SL140_Bars,";
        header += "SL150_Time,SL150_Precio,SL150_Pips,SL150_Bars,";
        header += "SL160_Time,SL160_Precio,SL160_Pips,SL160_Bars,";
        header += "SL170_Time,SL170_Precio,SL170_Pips,SL170_Bars,";
        header += "SL180_Time,SL180_Precio,SL180_Pips,SL180_Bars,";
        header += "SL190_Time,SL190_Precio,SL190_Pips,SL190_Bars,";
        header += "SL200_Time,SL200_Precio,SL200_Pips,SL200_Bars,";
        
        // Señal Contraria (1)
        header += "SeñalContraria_Time,SeñalContraria_Precio,SeñalContraria_Pips,SeñalContraria_Bars\r\n";
        
        FileWriteString(FileHandleResumen, header);
        Print("Archivo resumen creado: ", nombre_resumen);
    } else {
        Print("ERROR: No se pudo crear archivo de resumen");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Inicializar tracking virtual                                      |
//+------------------------------------------------------------------+
void InicializarTrackingVirtual() {
    TrackingBUY_A.activo = false;
    TrackingBUY_B.activo = false;
    TrackingBUY_C.activo = false;
    TrackingBUY_D.activo = false;
    TrackingBUY_E.activo = false;
    
    TrackingSELL_A.activo = false;
    TrackingSELL_B.activo = false;
    TrackingSELL_C.activo = false;
    TrackingSELL_D.activo = false;
    TrackingSELL_E.activo = false;
}

//+------------------------------------------------------------------+
//| Función auxiliar: Convertir periodo a string                      |
//+------------------------------------------------------------------+
string PeriodToString(int periodo) {
    switch(periodo) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        default: return "Unknown";
    }
}
//+------------------------------------------------------------------+
