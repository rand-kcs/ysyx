// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtestbench.h for the primary calling header

#include "verilated.h"

#include "Vtestbench__Syms.h"
#include "Vtestbench___024root.h"

VL_INLINE_OPT VlCoroutine Vtestbench___024root___eval_initial__TOP__0(Vtestbench___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtestbench__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtestbench___024root___eval_initial__TOP__0\n"); );
    // Init
    VlWide<5>/*159:0*/ __Vtemp_hdcf47f2e__0;
    // Body
    VL_WRITEF("[%0t] Tracing to logs/vlt_dump.fst\n",
              64,VL_TIME_UNITED_Q(1),-12);
    __Vtemp_hdcf47f2e__0[0U] = 0x2e667374U;
    __Vtemp_hdcf47f2e__0[1U] = 0x64756d70U;
    __Vtemp_hdcf47f2e__0[2U] = 0x766c745fU;
    __Vtemp_hdcf47f2e__0[3U] = 0x6f67732fU;
    __Vtemp_hdcf47f2e__0[4U] = 0x6cU;
    vlSymsp->_vm_contextp__->dumpfile(VL_CVT_PACK_STR_NW(5, __Vtemp_hdcf47f2e__0));
    vlSymsp->_traceDumpOpen();
    co_await vlSelf->__VdlySched.delay(0x32ULL, "vsrc/testbench.v", 
                                       14);
    VL_FINISH_MT("vsrc/testbench.v", 14, "");
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtestbench___024root___dump_triggers__ico(Vtestbench___024root* vlSelf);
#endif  // VL_DEBUG

void Vtestbench___024root___eval_triggers__ico(Vtestbench___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtestbench__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtestbench___024root___eval_triggers__ico\n"); );
    // Body
    vlSelf->__VicoTriggered.at(0U) = (0U == vlSelf->__VicoIterCount);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtestbench___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtestbench___024root___dump_triggers__act(Vtestbench___024root* vlSelf);
#endif  // VL_DEBUG

void Vtestbench___024root___eval_triggers__act(Vtestbench___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtestbench__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtestbench___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.at(0U) = vlSelf->__VdlySched.awaitingCurrentTime();
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtestbench___024root___dump_triggers__act(vlSelf);
    }
#endif
}
