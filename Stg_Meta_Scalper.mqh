/**
 * @file
 * Implements Scalper meta strategy.
 */

// Prevents processing this includes file multiple times.
#ifndef STG_META_SCALPER_MQH
#define STG_META_SCALPER_MQH

// User input params.
INPUT2_GROUP("Meta Scalper strategy: main params");
INPUT2 ENUM_STRATEGY Meta_Scalper_Strategy = STRAT_OSCILLATOR_TREND;  // Scalper strategy
INPUT2_GROUP("Meta Scalper strategy: common params");
INPUT2 float Meta_Scalper_LotSize = 0;                // Lot size
INPUT2 int Meta_Scalper_SignalOpenMethod = 0;         // Signal open method
INPUT2 float Meta_Scalper_SignalOpenLevel = 0;        // Signal open level
INPUT2 int Meta_Scalper_SignalOpenFilterMethod = 41;  // Signal open filter method
INPUT2 int Meta_Scalper_SignalOpenFilterTime = 3;     // Signal open filter time (0-31)
INPUT2 int Meta_Scalper_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT2 int Meta_Scalper_SignalCloseMethod = 0;        // Signal close method
INPUT2 int Meta_Scalper_SignalCloseFilter = 32;       // Signal close filter (-127-127)
INPUT2 float Meta_Scalper_SignalCloseLevel = 0;       // Signal close level
INPUT2 int Meta_Scalper_PriceStopMethod = 0;          // Price limit method
INPUT2 float Meta_Scalper_PriceStopLevel = 2;         // Price limit level
INPUT2 int Meta_Scalper_TickFilterMethod = 10;        // Tick filter method (0-255)
INPUT2 float Meta_Scalper_MaxSpread = 3.0;            // Max spread to trade (in pips)
INPUT2 short Meta_Scalper_Shift = 0;                  // Shift
INPUT2 float Meta_Scalper_OrderCloseLoss = 20;        // Order close loss
INPUT2 float Meta_Scalper_OrderCloseProfit = 10;      // Order close profit
INPUT2 int Meta_Scalper_OrderCloseTime = -10;         // Order close time in mins (>0) or bars (<0)

// Structs.
// Defines struct with default user strategy values.
struct Stg_Meta_Scalper_Params_Defaults : StgParams {
  Stg_Meta_Scalper_Params_Defaults()
      : StgParams(::Meta_Scalper_SignalOpenMethod, ::Meta_Scalper_SignalOpenFilterMethod,
                  ::Meta_Scalper_SignalOpenLevel, ::Meta_Scalper_SignalOpenBoostMethod,
                  ::Meta_Scalper_SignalCloseMethod, ::Meta_Scalper_SignalCloseFilter, ::Meta_Scalper_SignalCloseLevel,
                  ::Meta_Scalper_PriceStopMethod, ::Meta_Scalper_PriceStopLevel, ::Meta_Scalper_TickFilterMethod,
                  ::Meta_Scalper_MaxSpread, ::Meta_Scalper_Shift) {
    Set(STRAT_PARAM_LS, ::Meta_Scalper_LotSize);
    Set(STRAT_PARAM_OCL, ::Meta_Scalper_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, ::Meta_Scalper_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, ::Meta_Scalper_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, ::Meta_Scalper_SignalOpenFilterTime);
  }
};

class Stg_Meta_Scalper : public Strategy {
 protected:
  DictStruct<long, Ref<Strategy>> strats;

 public:
  Stg_Meta_Scalper(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Meta_Scalper *Init(ENUM_TIMEFRAMES _tf = NULL, EA *_ea = NULL) {
    // Initialize strategy initial values.
    Stg_Meta_Scalper_Params_Defaults stg_scalper_defaults;
    StgParams _stg_params(stg_scalper_defaults);
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_Meta_Scalper(_stg_params, _tparams, _cparams, "(Meta) Scalper");
    return _strat;
  }

  /**
   * Event on strategy's init.
   */
  void OnInit() { StrategyAdd(Meta_Scalper_Strategy, 0); }

  /**
   * Sets strategy.
   */
  bool StrategyAdd(ENUM_STRATEGY _sid, long _index = -1) {
    ENUM_TIMEFRAMES _tf = Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF);
    Ref<Strategy> _strat = StrategiesManager::StrategyInitByEnum(_sid, _tf);
    if (!_strat.IsSet()) {
      _strat = StrategiesMetaManager::StrategyInitByEnum((ENUM_STRATEGY_META)_sid, _tf);
    }
    if (_strat.IsSet()) {
      _strat.Ptr().Set<long>(STRAT_PARAM_ID, Get<long>(STRAT_PARAM_ID));
      _strat.Ptr().Set<ENUM_TIMEFRAMES>(STRAT_PARAM_TF, _tf);
      _strat.Ptr().Set<int>(STRAT_PARAM_TYPE, _sid);
      _strat.Ptr().OnInit();
      if (_index >= 0) {
        strats.Set(_index, _strat);
      } else {
        strats.Push(_strat);
      }
    }
    return _strat.IsSet();
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method, float _level = 0.0f, int _shift = 0) {
    bool _result = true;
    Ref<Strategy> _strat = strats.GetByKey(0);
    if (!_strat.IsSet()) {
      // Returns false when strategy is not set.
      return false;
    }
    _level = _level == 0.0f ? _strat.Ptr().Get<float>(STRAT_PARAM_SOL) : _level;
    _method = _method == 0 ? _strat.Ptr().Get<int>(STRAT_PARAM_SOM) : _method;
    _shift = _shift == 0 ? _strat.Ptr().Get<int>(STRAT_PARAM_SHIFT) : _shift;
    _result &= _strat.Ptr().SignalOpen(_cmd, _method, _level, _shift);
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method, float _level = 0.0f, int _shift = 0) {
    bool _result = true;
    Ref<Strategy> _strat = strats.GetByKey(0);
    if (!_strat.IsSet()) {
      // Returns false when strategy is not set.
      return false;
    }
    _level = _level == 0.0f ? _strat.Ptr().Get<float>(STRAT_PARAM_SOL) : _level;
    _method = _method == 0 ? _strat.Ptr().Get<int>(STRAT_PARAM_SOM) : _method;
    _shift = _shift == 0 ? _strat.Ptr().Get<int>(STRAT_PARAM_SHIFT) : _shift;
    _result &= _strat.Ptr().SignalOpen(Order::NegateOrderType(_cmd), _method, _level, _shift);
    return _result;
  }
};

#endif  // STG_META_SCALPER_MQH
