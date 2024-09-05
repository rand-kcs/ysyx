// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtop.h for the primary calling header

#include "verilated.h"

#include "Vtop___024root.h"

void Vtop___024root___eval_act(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_act\n"); );
}

extern const VlUnpacked<CData/*6:0*/, 16> Vtop__ConstPool__TABLE_h8aed404b_0;
extern const VlUnpacked<CData/*7:0*/, 256> Vtop__ConstPool__TABLE_hdda3d420_0;

VL_INLINE_OPT void Vtop___024root___nba_sequent__TOP__0(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*7:0*/ top__DOT__ascii;
    top__DOT__ascii = 0;
    CData/*3:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    CData/*3:0*/ __Vtableidx2;
    __Vtableidx2 = 0;
    CData/*3:0*/ __Vtableidx3;
    __Vtableidx3 = 0;
    CData/*3:0*/ __Vtableidx4;
    __Vtableidx4 = 0;
    CData/*7:0*/ __Vtableidx5;
    __Vtableidx5 = 0;
    CData/*3:0*/ __Vtableidx6;
    __Vtableidx6 = 0;
    CData/*3:0*/ __Vtableidx7;
    __Vtableidx7 = 0;
    CData/*2:0*/ __Vdly__top__DOT__mykeyboard__DOT__ps2_clk_sync;
    __Vdly__top__DOT__mykeyboard__DOT__ps2_clk_sync = 0;
    CData/*3:0*/ __Vdly__top__DOT__mykeyboard__DOT__count;
    __Vdly__top__DOT__mykeyboard__DOT__count = 0;
    IData/*31:0*/ __Vdly__top__DOT__segout1__DOT__displayCouter;
    __Vdly__top__DOT__segout1__DOT__displayCouter = 0;
    IData/*31:0*/ __Vdly__top__DOT__segout2__DOT__displayCouter;
    __Vdly__top__DOT__segout2__DOT__displayCouter = 0;
    // Body
    __Vdly__top__DOT__mykeyboard__DOT__ps2_clk_sync 
        = vlSelf->top__DOT__mykeyboard__DOT__ps2_clk_sync;
    __Vdly__top__DOT__mykeyboard__DOT__count = vlSelf->top__DOT__mykeyboard__DOT__count;
    __Vdly__top__DOT__segout2__DOT__displayCouter = vlSelf->top__DOT__segout2__DOT__displayCouter;
    __Vdly__top__DOT__segout1__DOT__displayCouter = vlSelf->top__DOT__segout1__DOT__displayCouter;
    __Vdly__top__DOT__mykeyboard__DOT__ps2_clk_sync 
        = ((6U & ((IData)(vlSelf->top__DOT__mykeyboard__DOT__ps2_clk_sync) 
                  << 1U)) | (IData)(vlSelf->ps2_clk));
    if (vlSelf->ready) {
        __Vdly__top__DOT__segout2__DOT__displayCouter = 0x9fffffU;
        __Vdly__top__DOT__segout1__DOT__displayCouter = 0x9fffffU;
    }
    if ((0U < vlSelf->top__DOT__segout2__DOT__displayCouter)) {
        __Vdly__top__DOT__segout2__DOT__displayCouter 
            = (vlSelf->top__DOT__segout2__DOT__displayCouter 
               - (IData)(1U));
        vlSelf->top__DOT____Vcellout__segout2____pinNumber4 
            = (((IData)(vlSelf->top__DOT__segout2__DOT____Vcellout__high____pinNumber2) 
                << 7U) | (IData)(vlSelf->top__DOT__segout2__DOT____Vcellout__low____pinNumber2));
    } else {
        vlSelf->top__DOT____Vcellout__segout2____pinNumber4 = 0x3fffU;
    }
    if ((0U < vlSelf->top__DOT__segout1__DOT__displayCouter)) {
        __Vdly__top__DOT__segout1__DOT__displayCouter 
            = (vlSelf->top__DOT__segout1__DOT__displayCouter 
               - (IData)(1U));
        vlSelf->top__DOT____Vcellout__segout1____pinNumber4 
            = (((IData)(vlSelf->top__DOT__segout1__DOT____Vcellout__high____pinNumber2) 
                << 7U) | (IData)(vlSelf->top__DOT__segout1__DOT____Vcellout__low____pinNumber2));
    } else {
        vlSelf->top__DOT____Vcellout__segout1____pinNumber4 = 0x3fffU;
    }
    vlSelf->top__DOT__segout2__DOT__displayCouter = __Vdly__top__DOT__segout2__DOT__displayCouter;
    vlSelf->top__DOT__segout1__DOT__displayCouter = __Vdly__top__DOT__segout1__DOT__displayCouter;
    vlSelf->count = ((IData)(vlSelf->rst) ? 0U : (0xffU 
                                                  & (((IData)(vlSelf->ready) 
                                                      & (0xf0U 
                                                         == (IData)(vlSelf->top__DOT__data)))
                                                      ? 
                                                     ((IData)(1U) 
                                                      + (IData)(vlSelf->count))
                                                      : (IData)(vlSelf->count))));
    __Vtableidx1 = (0xfU & (IData)(vlSelf->count));
    vlSelf->seg4 = Vtop__ConstPool__TABLE_h8aed404b_0
        [__Vtableidx1];
    __Vtableidx2 = (0xfU & ((IData)(vlSelf->count) 
                            >> 4U));
    vlSelf->seg5 = Vtop__ConstPool__TABLE_h8aed404b_0
        [__Vtableidx2];
    vlSelf->seg2 = (0x7fU & (IData)(vlSelf->top__DOT____Vcellout__segout2____pinNumber4));
    vlSelf->seg3 = (0x7fU & ((IData)(vlSelf->top__DOT____Vcellout__segout2____pinNumber4) 
                             >> 7U));
    vlSelf->seg0 = (0x7fU & (IData)(vlSelf->top__DOT____Vcellout__segout1____pinNumber4));
    vlSelf->seg1 = (0x7fU & ((IData)(vlSelf->top__DOT____Vcellout__segout1____pinNumber4) 
                             >> 7U));
    vlSelf->ready = 0U;
    if (vlSelf->rst) {
        __Vdly__top__DOT__mykeyboard__DOT__count = 0U;
    } else if ((IData)((4U == (6U & (IData)(vlSelf->top__DOT__mykeyboard__DOT__ps2_clk_sync))))) {
        if ((0xaU == (IData)(vlSelf->top__DOT__mykeyboard__DOT__count))) {
            if ((((~ (IData)(vlSelf->top__DOT__mykeyboard__DOT__buffer)) 
                  & (IData)(vlSelf->ps2_data)) & VL_REDXOR_32(
                                                              (0x1ffU 
                                                               & ((IData)(vlSelf->top__DOT__mykeyboard__DOT__buffer) 
                                                                  >> 1U))))) {
                vlSelf->top__DOT__data = (0xffU & ((IData)(vlSelf->top__DOT__mykeyboard__DOT__buffer) 
                                                   >> 1U));
                vlSelf->ready = 1U;
            }
            __Vdly__top__DOT__mykeyboard__DOT__count = 0U;
        } else {
            vlSelf->top__DOT__mykeyboard__DOT____Vlvbound_h1a91ade8__0 
                = vlSelf->ps2_data;
            if ((9U >= (IData)(vlSelf->top__DOT__mykeyboard__DOT__count))) {
                vlSelf->top__DOT__mykeyboard__DOT__buffer 
                    = (((~ ((IData)(1U) << (IData)(vlSelf->top__DOT__mykeyboard__DOT__count))) 
                        & (IData)(vlSelf->top__DOT__mykeyboard__DOT__buffer)) 
                       | (0x3ffU & ((IData)(vlSelf->top__DOT__mykeyboard__DOT____Vlvbound_h1a91ade8__0) 
                                    << (IData)(vlSelf->top__DOT__mykeyboard__DOT__count))));
            }
            __Vdly__top__DOT__mykeyboard__DOT__count 
                = (0xfU & ((IData)(1U) + (IData)(vlSelf->top__DOT__mykeyboard__DOT__count)));
        }
    }
    vlSelf->top__DOT__mykeyboard__DOT__count = __Vdly__top__DOT__mykeyboard__DOT__count;
    vlSelf->top__DOT__mykeyboard__DOT__ps2_clk_sync 
        = __Vdly__top__DOT__mykeyboard__DOT__ps2_clk_sync;
    __Vtableidx3 = (0xfU & (IData)(vlSelf->top__DOT__data));
    vlSelf->top__DOT__segout1__DOT____Vcellout__low____pinNumber2 
        = Vtop__ConstPool__TABLE_h8aed404b_0[__Vtableidx3];
    __Vtableidx4 = (0xfU & ((IData)(vlSelf->top__DOT__data) 
                            >> 4U));
    vlSelf->top__DOT__segout1__DOT____Vcellout__high____pinNumber2 
        = Vtop__ConstPool__TABLE_h8aed404b_0[__Vtableidx4];
    __Vtableidx5 = vlSelf->top__DOT__data;
    top__DOT__ascii = Vtop__ConstPool__TABLE_hdda3d420_0
        [__Vtableidx5];
    __Vtableidx6 = (0xfU & (IData)(top__DOT__ascii));
    vlSelf->top__DOT__segout2__DOT____Vcellout__low____pinNumber2 
        = Vtop__ConstPool__TABLE_h8aed404b_0[__Vtableidx6];
    __Vtableidx7 = (0xfU & ((IData)(top__DOT__ascii) 
                            >> 4U));
    vlSelf->top__DOT__segout2__DOT____Vcellout__high____pinNumber2 
        = Vtop__ConstPool__TABLE_h8aed404b_0[__Vtableidx7];
}

void Vtop___024root___eval_nba(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_nba\n"); );
    // Body
    if (vlSelf->__VnbaTriggered.at(0U)) {
        Vtop___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vtop___024root___eval_triggers__act(Vtop___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__act(Vtop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtop___024root___dump_triggers__nba(Vtop___024root* vlSelf);
#endif  // VL_DEBUG

void Vtop___024root___eval(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        __VnbaContinue = 0U;
        vlSelf->__VnbaTriggered.clear();
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            vlSelf->__VactContinue = 0U;
            Vtop___024root___eval_triggers__act(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    Vtop___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("vsrc/top.v", 1, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                Vtop___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                Vtop___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("vsrc/top.v", 1, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            Vtop___024root___eval_nba(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
void Vtop___024root___eval_debug_assertions(Vtop___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst & 0xfeU))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY((vlSelf->ps2_clk & 0xfeU))) {
        Verilated::overWidthError("ps2_clk");}
    if (VL_UNLIKELY((vlSelf->ps2_data & 0xfeU))) {
        Verilated::overWidthError("ps2_data");}
}
#endif  // VL_DEBUG
