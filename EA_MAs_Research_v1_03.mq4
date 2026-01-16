//+------------------------------------------------------------------+
//|                                         EA_MAs_Research_v1.mq4   |
//|                                    Expert Advisor de Investigación|
//|                          Sistema de Medias Móviles Multi-Salida  |
//+------------------------------------------------------------------+
#property copyright "Guido - Investigación MAs"
#property version   "1.03"
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
extern bool      Eval_Combinacion_E = true;  // a+c+d
extern bool      Eval_Combinacion_F = true;  // a+d+e
extern bool      Eval_Combinacion_G = false; // Reservado

extern string    S3 = "===== SALIDAS PIPS FIJOS =====";
extern bool      Salida_Pips_5 = true;
extern bool      Salida_Pips_10 = true;
extern bool      Salida_Pips_15 = true;
extern bool      Salida_Pips_20 = true;
extern bool      Salida_Pips_25 = true;
extern bool      Salida_Pips_30 = true;
extern bool      Salida_Pips_50 = true;
extern bool      Salida_Pips_60 = true;
extern bool      Salida_Pips_75 = true;
extern bool      Salida_Pips_80 = true;
extern bool      Salida_Pips_85 = true;
extern bool      Salida_Pips_100 = true;

extern string    S4 = "===== SALIDAS RETROCESO =====";
extern bool      Salida_Retroceso_20 = true;
extern bool      Salida_Retroceso_25 = true;
extern bool      Salida_Retroceso_30 = true;
extern bool      Salida_Retroceso_35 = true;
extern bool      Salida_Retroceso_40 = true;
extern bool      Salida_Retroceso_45 = true;
extern bool      Salida_Retroceso_50 = true;

extern string    S5 = "===== SALIDAS CRUCES INVERSOS =====";
extern bool      Salida_Cruce_d = true;  // LWMA20 vs LWMA22
extern bool      Salida_Cruce_c = true;  // LWMA50 vs LWMA53
extern bool      Salida_Cruce_b = true;  // LWMA100 vs LWMA105

extern string    S6 = "===== PROTECCIÓN Y TIMEOUT =====";
extern int       StopLossVirtual_Pips = 200;
extern int       MaxBars_Timeout = 500;
extern double    UmbralMinimoPips = 1.0;

extern string    S7 = "===== EXPORT Y LOGGING =====";
extern bool      ExportarCSV = true;
extern bool      LoggingDetallado = true;
extern int       BarsHistoriaMinima = 250;
extern int       BufferCSV_Lineas = 100; // Escribir cada 100 líneas

//+------------------------------------------------------------------+
//| VARIABLES GLOBALES                                                |
//+------------------------------------------------------------------+
datetime LastBarTime = 0;
int FileHandleSeñales = -1;
int FileHandleResumen = -1;
double PipValue = 1.0;
int SimboloDigits = 0;
string SimboloActual = "";

// Contadores
int ContadorIDSeñales = 0;
int TotalSeñalesDetectadas = 0;
int TotalTradesActivos = 0;

// OPTIMIZACIÓN: Caché de MAs
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

// OPTIMIZACIÓN: Buffer de escritura CSV
string BufferCSVResumen = "";
int ContadorBufferResumen = 0;

//+------------------------------------------------------------------+
//| ESTRUCTURA EXTENDIDA - Información de salida individual           |
//+------------------------------------------------------------------+
struct InfoSalida {
    bool      cerrada;
    datetime  timestamp;
    double    precio;
    double    pips;
    int       bars;
};

//+------------------------------------------------------------------+
//| ESTRUCTURA DE DATOS PARA TRACKING VIRTUAL - EXTENDIDA             |
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
    
    // NUEVO: Información detallada de cada salida
    InfoSalida salida_pips_5_info;
    InfoSalida salida_pips_10_info;
    InfoSalida salida_pips_15_info;
    InfoSalida salida_pips_20_info;
    InfoSalida salida_pips_25_info;
    InfoSalida salida_pips_30_info;
    InfoSalida salida_pips_50_info;
    InfoSalida salida_pips_60_info;
    InfoSalida salida_pips_75_info;
    InfoSalida salida_pips_80_info;
    InfoSalida salida_pips_85_info;
    InfoSalida salida_pips_100_info;
    
    InfoSalida salida_retroceso_20_info;
    InfoSalida salida_retroceso_25_info;
    InfoSalida salida_retroceso_30_info;
    InfoSalida salida_retroceso_35_info;
    InfoSalida salida_retroceso_40_info;
    InfoSalida salida_retroceso_45_info;
    InfoSalida salida_retroceso_50_info;
    
    InfoSalida salida_cruce_d_info;
    InfoSalida salida_cruce_c_info;
    InfoSalida salida_cruce_b_info;
    
    InfoSalida salida_stoploss_info;
    InfoSalida salida_timeout_info;
    
    // MAs al entry y exit
    double    ma200_entry, ma220_entry, ma100_entry, ma105_entry;
    double    ma50_entry, ma53_entry, ma20_entry, ma22_entry, ma5_entry;
    
    double    ma200_exit, ma220_exit, ma100_exit, ma105_exit;
    double    ma50_exit, ma53_exit, ma20_exit, ma22_exit, ma5_exit;
    
    // NUEVO: Contexto temporal
    int       hora_entrada;
    int       dia_semana_entrada;
    
    bool      activo;
    bool      todas_salidas_cerradas;
};

// Arrays de tracking virtual
TradeVirtual TrackingBUY_A, TrackingBUY_B, TrackingBUY_C, TrackingBUY_E, TrackingBUY_F;
TradeVirtual TrackingSELL_A, TrackingSELL_B, TrackingSELL_C, TrackingSELL_E, TrackingSELL_F;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit() {
    Print("==================================================");
    Print("EA_MAs_Research_v1.03 - INICIANDO");
    
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
    
    Print("EA_MAs_Research_v1.03 - INICIALIZADO CORRECTAMENTE");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("==================================================");
    Print("EA_MAs_Research_v1.03 - FINALIZANDO");
    Print("Razón: ", reason);
    Print("Total Señales Detectadas: ", TotalSeñalesDetectadas);
    
    // Flush buffer final
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
    // OPTIMIZACIÓN: Solo operar en nuevo bar
    if(OperarSoloEnNuevaBarra) {
        if(Time[0] == LastBarTime) return;
        LastBarTime = Time[0];
    }
    
    if(Bars < BarsHistoriaMinima || Bars < 2) return;
    
    // OPTIMIZACIÓN: Invalidar caché de MAs en nuevo bar
    MAsCacheValido = false;
    
    // OPTIMIZACIÓN: Early exit si no hay tracking activo y no hay que evaluar señales
    bool hayTrackingActivo = (TrackingBUY_A.activo || TrackingBUY_B.activo || TrackingBUY_C.activo || 
                              TrackingBUY_E.activo || TrackingBUY_F.activo ||
                              TrackingSELL_A.activo || TrackingSELL_B.activo || TrackingSELL_C.activo || 
                              TrackingSELL_E.activo || TrackingSELL_F.activo);
    
    // Calcular MAs solo cuando sea necesario
    MediasMoviles mas;
    if(!ObtenerMAsConCache(mas)) {
        if(LoggingDetallado) {
            Print("ERROR: No se pudieron calcular medias móviles en bar ", Time[0]);
        }
        return;
    }
    
    // Evaluar señales nuevas
    EvaluarTodasLasSeñales(mas);
    
    // Actualizar tracking activo
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
    // Evaluar condiciones individuales UNA SOLA VEZ
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
    
    if(Eval_Combinacion_E) {
        bool señal_buy_E = cond_a && cond_c && cond_d;
        ProcesarSeñal(señal_buy_E, "BUY", "E", mas, TrackingBUY_E,
                     cond_a, cond_b, cond_c, cond_d, cond_e);
    }
    
    if(Eval_Combinacion_F) {
        bool señal_buy_F = cond_a && cond_d && cond_e;
        ProcesarSeñal(señal_buy_F, "BUY", "F", mas, TrackingBUY_F,
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
    
    if(Eval_Combinacion_E) {
        bool señal_sell_E = cond_a_sell && cond_c_sell && cond_d_sell;
        ProcesarSeñal(señal_sell_E, "SELL", "E", mas, TrackingSELL_E,
                     cond_a_sell, cond_b_sell, cond_c_sell, cond_d_sell, cond_e_sell);
    }
    
    if(Eval_Combinacion_F) {
        bool señal_sell_F = cond_a_sell && cond_d_sell && cond_e_sell;
        ProcesarSeñal(señal_sell_F, "SELL", "F", mas, TrackingSELL_F,
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
    if(TrackingBUY_E.activo) ActualizarTrackingVirtual(TrackingBUY_E, mas);
    if(TrackingBUY_F.activo) ActualizarTrackingVirtual(TrackingBUY_F, mas);
    
    if(TrackingSELL_A.activo) ActualizarTrackingVirtual(TrackingSELL_A, mas);
    if(TrackingSELL_B.activo) ActualizarTrackingVirtual(TrackingSELL_B, mas);
    if(TrackingSELL_C.activo) ActualizarTrackingVirtual(TrackingSELL_C, mas);
    if(TrackingSELL_E.activo) ActualizarTrackingVirtual(TrackingSELL_E, mas);
    if(TrackingSELL_F.activo) ActualizarTrackingVirtual(TrackingSELL_F, mas);
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
//| Procesar señal detectada - EXTENDIDO con condiciones              |
//+------------------------------------------------------------------+
void ProcesarSeñal(bool señal_activa, string tipo, string combinacion, 
                   MediasMoviles &mas, TradeVirtual &tracking,
                   bool cond_a, bool cond_b, bool cond_c, bool cond_d, bool cond_e) {
    
    // NUEVO: Registrar TODAS las señales (activadas o no)
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
    
    // Iniciar tracking si no está activo
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
    
    // NUEVO: Contexto temporal
    MqlDateTime dt;
    TimeToStruct(Time[1], dt);
    tracking.hora_entrada = dt.hour;
    tracking.dia_semana_entrada = dt.day_of_week;
    
    // Guardar MAs al entry
    tracking.ma200_entry = mas.ma200_close;
    tracking.ma220_entry = mas.ma220_open;
    tracking.ma100_entry = mas.ma100_close;
    tracking.ma105_entry = mas.ma105_open;
    tracking.ma50_entry = mas.ma50_close;
    tracking.ma53_entry = mas.ma53_open;
    tracking.ma20_entry = mas.ma20_close;
    tracking.ma22_entry = mas.ma22_open;
    tracking.ma5_entry = mas.ma5_close;
    
    // Inicializar todas las salidas
    InicializarSalida(tracking.salida_pips_5_info);
    InicializarSalida(tracking.salida_pips_10_info);
    InicializarSalida(tracking.salida_pips_15_info);
    InicializarSalida(tracking.salida_pips_20_info);
    InicializarSalida(tracking.salida_pips_25_info);
    InicializarSalida(tracking.salida_pips_30_info);
    InicializarSalida(tracking.salida_pips_50_info);
    InicializarSalida(tracking.salida_pips_60_info);
    InicializarSalida(tracking.salida_pips_75_info);
    InicializarSalida(tracking.salida_pips_80_info);
    InicializarSalida(tracking.salida_pips_85_info);
    InicializarSalida(tracking.salida_pips_100_info);
    
    InicializarSalida(tracking.salida_retroceso_20_info);
    InicializarSalida(tracking.salida_retroceso_25_info);
    InicializarSalida(tracking.salida_retroceso_30_info);
    InicializarSalida(tracking.salida_retroceso_35_info);
    InicializarSalida(tracking.salida_retroceso_40_info);
    InicializarSalida(tracking.salida_retroceso_45_info);
    InicializarSalida(tracking.salida_retroceso_50_info);
    
    InicializarSalida(tracking.salida_cruce_d_info);
    InicializarSalida(tracking.salida_cruce_c_info);
    InicializarSalida(tracking.salida_cruce_b_info);
    
    InicializarSalida(tracking.salida_stoploss_info);
    InicializarSalida(tracking.salida_timeout_info);
    
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
    
    // Actualizar máximo y mínimo
    if(tracking.pips_actual > tracking.pips_maximo) {
        tracking.pips_maximo = tracking.pips_actual;
        tracking.precio_maximo = precio_actual;
        tracking.timestamp_maximo = Time[0];
    }
    if(tracking.pips_actual < tracking.pips_minimo) {
        tracking.pips_minimo = tracking.pips_actual;
        tracking.precio_minimo = precio_actual;
    }
    
    // OPTIMIZACIÓN: Solo evaluar salidas no cerradas
    EvaluarSalidasPipsFijos(tracking);
    EvaluarSalidasRetroceso(tracking);
    EvaluarSalidasCruces(tracking, mas);
    EvaluarSalidasProteccion(tracking);
    
    if(TodasLasSalidasCerradas(tracking) || tracking.bars_duracion >= MaxBars_Timeout) {
        FinalizarTrackingVirtual(tracking, mas);
    }
}

//+------------------------------------------------------------------+
//| Evaluar salidas por pips fijos - OPTIMIZADO                       |
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
    
    if(Salida_Pips_50 && !tracking.salida_pips_50_info.cerrada && tracking.pips_actual >= 50) {
        RegistrarSalidaEnStruct(tracking.salida_pips_50_info, tracking);
    }
    
    if(Salida_Pips_60 && !tracking.salida_pips_60_info.cerrada && tracking.pips_actual >= 60) {
        RegistrarSalidaEnStruct(tracking.salida_pips_60_info, tracking);
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
    
    if(Salida_Pips_100 && !tracking.salida_pips_100_info.cerrada && tracking.pips_actual >= 100) {
        RegistrarSalidaEnStruct(tracking.salida_pips_100_info, tracking);
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
//| Evaluar salidas por cruces                                        |
//+------------------------------------------------------------------+
void EvaluarSalidasCruces(TradeVirtual &tracking, MediasMoviles &mas) {
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
}

//+------------------------------------------------------------------+
//| Evaluar salidas de protección                                     |
//+------------------------------------------------------------------+
void EvaluarSalidasProteccion(TradeVirtual &tracking) {
    if(StopLossVirtual_Pips > 0 && !tracking.salida_stoploss_info.cerrada) {
        if(tracking.pips_actual <= -StopLossVirtual_Pips) {
            RegistrarSalidaEnStruct(tracking.salida_stoploss_info, tracking);
            
            if(LoggingDetallado) {
                Print("STOP LOSS - ", tracking.tipo, " Combinación ", tracking.combinacion,
                      " | Pips: ", DoubleToString(tracking.pips_actual, 2));
            }
        }
    }
    
    if(MaxBars_Timeout > 0 && !tracking.salida_timeout_info.cerrada) {
        if(tracking.bars_duracion >= MaxBars_Timeout) {
            RegistrarSalidaEnStruct(tracking.salida_timeout_info, tracking);
            
            if(LoggingDetallado) {
                Print("TIMEOUT - ", tracking.tipo, " Combinación ", tracking.combinacion,
                      " | Bars: ", tracking.bars_duracion);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Verificar si todas las salidas están cerradas                     |
//+------------------------------------------------------------------+
bool TodasLasSalidasCerradas(TradeVirtual &tracking) {
    int salidas_habilitadas = 0;
    int salidas_cerradas = 0;
    
    if(Salida_Pips_5) { salidas_habilitadas++; if(tracking.salida_pips_5_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_10) { salidas_habilitadas++; if(tracking.salida_pips_10_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_15) { salidas_habilitadas++; if(tracking.salida_pips_15_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_20) { salidas_habilitadas++; if(tracking.salida_pips_20_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_25) { salidas_habilitadas++; if(tracking.salida_pips_25_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_30) { salidas_habilitadas++; if(tracking.salida_pips_30_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_50) { salidas_habilitadas++; if(tracking.salida_pips_50_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_60) { salidas_habilitadas++; if(tracking.salida_pips_60_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_75) { salidas_habilitadas++; if(tracking.salida_pips_75_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_80) { salidas_habilitadas++; if(tracking.salida_pips_80_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_85) { salidas_habilitadas++; if(tracking.salida_pips_85_info.cerrada) salidas_cerradas++; }
    if(Salida_Pips_100) { salidas_habilitadas++; if(tracking.salida_pips_100_info.cerrada) salidas_cerradas++; }
    
    if(Salida_Retroceso_20) { salidas_habilitadas++; if(tracking.salida_retroceso_20_info.cerrada) salidas_cerradas++; }
    if(Salida_Retroceso_25) { salidas_habilitadas++; if(tracking.salida_retroceso_25_info.cerrada) salidas_cerradas++; }
    if(Salida_Retroceso_30) { salidas_habilitadas++; if(tracking.salida_retroceso_30_info.cerrada) salidas_cerradas++; }
    if(Salida_Retroceso_35) { salidas_habilitadas++; if(tracking.salida_retroceso_35_info.cerrada) salidas_cerradas++; }
    if(Salida_Retroceso_40) { salidas_habilitadas++; if(tracking.salida_retroceso_40_info.cerrada) salidas_cerradas++; }
    if(Salida_Retroceso_45) { salidas_habilitadas++; if(tracking.salida_retroceso_45_info.cerrada) salidas_cerradas++; }
    if(Salida_Retroceso_50) { salidas_habilitadas++; if(tracking.salida_retroceso_50_info.cerrada) salidas_cerradas++; }
    
    if(Salida_Cruce_d) { salidas_habilitadas++; if(tracking.salida_cruce_d_info.cerrada) salidas_cerradas++; }
    if(Salida_Cruce_c) { salidas_habilitadas++; if(tracking.salida_cruce_c_info.cerrada) salidas_cerradas++; }
    if(Salida_Cruce_b) { salidas_habilitadas++; if(tracking.salida_cruce_b_info.cerrada) salidas_cerradas++; }
    
    if(tracking.salida_stoploss_info.cerrada) salidas_cerradas++;
    if(tracking.salida_timeout_info.cerrada) salidas_cerradas++;
    
    return (salidas_cerradas >= salidas_habilitadas) || 
           tracking.salida_stoploss_info.cerrada || 
           tracking.salida_timeout_info.cerrada;
}

//+------------------------------------------------------------------+
//| Finalizar tracking y registrar resumen completo                   |
//+------------------------------------------------------------------+
void FinalizarTrackingVirtual(TradeVirtual &tracking, MediasMoviles &mas) {
    // Guardar MAs al exit
    tracking.ma200_exit = mas.ma200_close;
    tracking.ma220_exit = mas.ma220_open;
    tracking.ma100_exit = mas.ma100_close;
    tracking.ma105_exit = mas.ma105_open;
    tracking.ma50_exit = mas.ma50_close;
    tracking.ma53_exit = mas.ma53_open;
    tracking.ma20_exit = mas.ma20_close;
    tracking.ma22_exit = mas.ma22_open;
    tracking.ma5_exit = mas.ma5_close;
    
    // NUEVO: Registrar resumen completo en formato WIDE
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
//| NUEVO: Registrar señal con TODAS las condiciones                  |
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
//| NUEVO: Registrar resumen completo en formato WIDE                 |
//+------------------------------------------------------------------+
void RegistrarResumenCompleto(TradeVirtual &tracking) {
    if(FileHandleResumen < 0) return;
    
    // OPTIMIZACIÓN: Usar buffer para acumular líneas
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
                   
                   // MAs Entry
                   DoubleToString(tracking.ma200_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma220_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma100_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma105_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma50_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma53_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma20_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma22_entry, SimboloDigits) + "," +
                   DoubleToString(tracking.ma5_entry, SimboloDigits) + "," +
                   
                   // MAs Exit
                   DoubleToString(tracking.ma200_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma220_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma100_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma105_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma50_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma53_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma20_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma22_exit, SimboloDigits) + "," +
                   DoubleToString(tracking.ma5_exit, SimboloDigits) + "," +
                   
                   // Todas las salidas (timestamp, precio, pips, bars)
                   FormatearSalida(tracking.salida_pips_5_info) +
                   FormatearSalida(tracking.salida_pips_10_info) +
                   FormatearSalida(tracking.salida_pips_15_info) +
                   FormatearSalida(tracking.salida_pips_20_info) +
                   FormatearSalida(tracking.salida_pips_25_info) +
                   FormatearSalida(tracking.salida_pips_30_info) +
                   FormatearSalida(tracking.salida_pips_50_info) +
                   FormatearSalida(tracking.salida_pips_60_info) +
                   FormatearSalida(tracking.salida_pips_75_info) +
                   FormatearSalida(tracking.salida_pips_80_info) +
                   FormatearSalida(tracking.salida_pips_85_info) +
                   FormatearSalida(tracking.salida_pips_100_info) +
                   
                   FormatearSalida(tracking.salida_retroceso_20_info) +
                   FormatearSalida(tracking.salida_retroceso_25_info) +
                   FormatearSalida(tracking.salida_retroceso_30_info) +
                   FormatearSalida(tracking.salida_retroceso_35_info) +
                   FormatearSalida(tracking.salida_retroceso_40_info) +
                   FormatearSalida(tracking.salida_retroceso_45_info) +
                   FormatearSalida(tracking.salida_retroceso_50_info) +
                   
                   FormatearSalida(tracking.salida_cruce_d_info) +
                   FormatearSalida(tracking.salida_cruce_c_info) +
                   FormatearSalida(tracking.salida_cruce_b_info) +
                   
                   FormatearSalida(tracking.salida_stoploss_info) +
                   FormatearSalida(tracking.salida_timeout_info, true) + "\r\n"; // último sin coma
    
    // OPTIMIZACIÓN: Acumular en buffer
    BufferCSVResumen += linea;
    ContadorBufferResumen++;
    
    // Escribir cuando el buffer alcanza el límite
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
    
    // Archivo de señales DETALLADAS
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
    
    // Archivo de RESUMEN COMPLETO (formato WIDE)
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
        header += "P50_Time,P50_Precio,P50_Pips,P50_Bars,";
        header += "P60_Time,P60_Precio,P60_Pips,P60_Bars,";
        header += "P75_Time,P75_Precio,P75_Pips,P75_Bars,";
        header += "P80_Time,P80_Precio,P80_Pips,P80_Bars,";
        header += "P85_Time,P85_Precio,P85_Pips,P85_Bars,";
        header += "P100_Time,P100_Precio,P100_Pips,P100_Bars,";
        header += "R20_Time,R20_Precio,R20_Pips,R20_Bars,";
        header += "R25_Time,R25_Precio,R25_Pips,R25_Bars,";
        header += "R30_Time,R30_Precio,R30_Pips,R30_Bars,";
        header += "R35_Time,R35_Precio,R35_Pips,R35_Bars,";
        header += "R40_Time,R40_Precio,R40_Pips,R40_Bars,";
        header += "R45_Time,R45_Precio,R45_Pips,R45_Bars,";
        header += "R50_Time,R50_Precio,R50_Pips,R50_Bars,";
        header += "Cruce_d_Time,Cruce_d_Precio,Cruce_d_Pips,Cruce_d_Bars,";
        header += "Cruce_c_Time,Cruce_c_Precio,Cruce_c_Pips,Cruce_c_Bars,";
        header += "Cruce_b_Time,Cruce_b_Precio,Cruce_b_Pips,Cruce_b_Bars,";
        header += "SL_Time,SL_Precio,SL_Pips,SL_Bars,";
        header += "Timeout_Time,Timeout_Precio,Timeout_Pips,Timeout_Bars\r\n";
        
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
    TrackingBUY_E.activo = false;
    TrackingBUY_F.activo = false;
    
    TrackingSELL_A.activo = false;
    TrackingSELL_B.activo = false;
    TrackingSELL_C.activo = false;
    TrackingSELL_E.activo = false;
    TrackingSELL_F.activo = false;
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
