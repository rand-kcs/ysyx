// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"

class Vtop__Syms;

class Vtop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(ps2_clk,0,0);
    VL_IN8(ps2_data,0,0);
    VL_OUT8(seg0,6,0);
    VL_OUT8(seg1,6,0);
    VL_OUT8(seg2,6,0);
    VL_OUT8(seg3,6,0);
    VL_OUT8(seg4,6,0);
    VL_OUT8(seg5,6,0);
    VL_OUT8(count,7,0);
    VL_OUT8(ready,0,0);
    CData/*7:0*/ top__DOT__data;
    CData/*3:0*/ top__DOT__mykeyboard__DOT__count;
    CData/*2:0*/ top__DOT__mykeyboard__DOT__ps2_clk_sync;
    CData/*0:0*/ top__DOT__mykeyboard__DOT____Vlvbound_h1a91ade8__0;
    CData/*6:0*/ top__DOT__segout1__DOT____Vcellout__low____pinNumber2;
    CData/*6:0*/ top__DOT__segout1__DOT____Vcellout__high____pinNumber2;
    CData/*6:0*/ top__DOT__segout2__DOT____Vcellout__low____pinNumber2;
    CData/*6:0*/ top__DOT__segout2__DOT____Vcellout__high____pinNumber2;
    CData/*0:0*/ __Vtrigrprev__TOP__clk;
    CData/*0:0*/ __VactContinue;
    SData/*13:0*/ top__DOT____Vcellout__segout1____pinNumber4;
    SData/*13:0*/ top__DOT____Vcellout__segout2____pinNumber4;
    SData/*9:0*/ top__DOT__mykeyboard__DOT__buffer;
    IData/*31:0*/ top__DOT__segout1__DOT__displayCouter;
    IData/*31:0*/ top__DOT__segout2__DOT__displayCouter;
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* v__name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard
