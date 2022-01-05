var documenterSearchIndex = {"docs":
[{"location":"functions/","page":"Functions","title":"Functions","text":"CurrentModule = KiteModels","category":"page"},{"location":"functions/#Introduction","page":"Functions","title":"Introduction","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"Most of the functions work on a KPS3 object. For this, the variable s is used. Such a variable can be created with the lines:","category":"page"},{"location":"functions/","page":"Functions","title":"Functions","text":"using KiteUtils, KitePodSimulator\nconst s = KPS3(KCU())","category":"page"},{"location":"functions/#Input-functions","page":"Functions","title":"Input functions","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"set_v_reel_out\nset_l_tether\nset_depower_steering","category":"page"},{"location":"functions/#KiteModels.set_v_reel_out","page":"Functions","title":"KiteModels.set_v_reel_out","text":"set_v_reel_out(s::AKM, v_reel_out, t_0, period_time = 1.0 / s.set.sample_freq)\n\nSetter for the reel-out speed. Must be called on every timestep (before each simulation). It also updates the tether length, therefore it must be called even if v_reelout has not changed.\n\nt_0 the start time of the next timestep relative to the start of the simulation [s]\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.set_l_tether","page":"Functions","title":"KiteModels.set_l_tether","text":"set_l_tether(s::AKM, l_tether)\n\nSetter for the tether reel-out lenght (at zero force). During real-time simulations use the function set_v_reel_out instead.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.set_depower_steering","page":"Functions","title":"KiteModels.set_depower_steering","text":"set_depower_steering(s::KPS3, depower, steering)\n\nSetter for the depower and steering model inputs. \n\nvalid range for steering: -1.0 .. 1.0.  \nvalid range for depower: 0 .. 1.0\n\nThis function sets the variables s.depower, s.steering and s.alpha_depower. \n\nIt takes the depower offset c0 and the dependency of the steering sensitivity from the depower settings into account.\n\n\n\n\n\n","category":"function"},{"location":"functions/#Output-functions","page":"Functions","title":"Output functions","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"get_l_tether\nget_force\nget_spring_forces\nget_lift_drag\nget_lod","category":"page"},{"location":"functions/#KiteModels.get_l_tether","page":"Functions","title":"KiteModels.get_l_tether","text":"get_l_tether(s::AKM)\n\nGetter for the tether reel-out lenght (at zero force).\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.get_force","page":"Functions","title":"KiteModels.get_force","text":"get_force(s::AKM)\n\nReturn the absolute value of the force at the winch as calculated during the last timestep. \n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.get_spring_forces","page":"Functions","title":"KiteModels.get_spring_forces","text":"get_spring_forces(s::AKM, pos)\n\nReturns an array of the scalar spring forces of all tether segements.\n\nInput: The vector pos of the positions of the point masses that belong to the tether.    \n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.get_lift_drag","page":"Functions","title":"KiteModels.get_lift_drag","text":"get_lift_drag(s::AKM)\n\nReturns a tuple of the scalar lift and drag forces. \n\nExample:  \n\nlift, drag = get_lift_drag(kps)\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.get_lod","page":"Functions","title":"KiteModels.get_lod","text":"get_lod(s::AKM)\n\nReturns the lift-over-drag ratio.\n\n\n\n\n\n","category":"function"},{"location":"functions/#Callback-function-for-the-DAE-solver","page":"Functions","title":"Callback function for the DAE solver","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"residual!","category":"page"},{"location":"functions/#KiteModels.residual!","page":"Functions","title":"KiteModels.residual!","text":"residual!(res, yd, y::MVector{S, SimFloat}, s::KPS3, time) where S\n\nN-point tether model, one point kite at the top:\nInputs:\nState vector y   = pos1, pos2, ..., posn, vel1, vel2, ..., veln\nDerivative   yd  = vel1, vel2, ..., veln, acc1, acc2, ..., accn\nOutput:\nResidual     res = res1, res2 = pos1,  ..., vel1, ...\n\nStruct with work variables: s of type KPS3\nThe parameter S is the dimension of the state vector.\nN = S/6, each point is represented by two 3 element vectors.\n\n\n\n\n\n","category":"function"},{"location":"functions/#Conversion-functions","page":"Functions","title":"Conversion functions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = KiteModels","category":"page"},{"location":"#KiteModels","page":"Home","title":"KiteModels","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for the package KiteModels.","category":"page"},{"location":"#Background","page":"Home","title":"Background","text":"","category":"section"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Download Julia 1.6 or later, if you haven't already. You can add KiteModels from  Julia's package manager, by typing ","category":"page"},{"location":"","page":"Home","title":"Home","text":"] add KiteModels","category":"page"},{"location":"","page":"Home","title":"Home","text":"at the Julia prompt.","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you are using Windows, it is suggested to install git and bash, too. This is explained for example here: Julia on Windows .","category":"page"},{"location":"#Provides","page":"Home","title":"Provides","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The type AbstractKiteModel with the implementation KPS3 and the residual! function for a DAE solver, representing the model. Other kite models can be added inside or outside of this package by implementing the non-generic methods required for an AbstractKiteModel.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Additional functions to provide inputs and outputs of the model on each time step. Per time step the residual! function is called as many times as needed to find the solution at the end of the time step. The formulas are based on basic physics and aerodynamics and can be quite simple because a differential algebraic notation is used.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Author: Uwe Fechner (uwe.fechner.msc@gmail.com)","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"CurrentModule = KiteModels","category":"page"},{"location":"parameters/#Configuration","page":"Parameters","title":"Configuration","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"To configure the parameters of the kite models, edit the file data/settings.yaml , or create a copy under a different name and change the name of the active configuration in the file data/system.yaml .","category":"page"},{"location":"parameters/#Parameters","page":"Parameters","title":"Parameters","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"The following parameters are used by this package:","category":"page"},{"location":"types/#Exported-Types","page":"Types","title":"Exported Types","text":"","category":"section"},{"location":"types/","page":"Types","title":"Types","text":"CurrentModule = KiteModels","category":"page"},{"location":"types/#Basic-types","page":"Types","title":"Basic types","text":"","category":"section"},{"location":"types/","page":"Types","title":"Types","text":"SimFloat\nKVec3\nSVec3\nProfileLaw\nAbstractKiteModel","category":"page"},{"location":"types/#KiteModels.SimFloat","page":"Types","title":"KiteModels.SimFloat","text":"const SimFloat = Float64\n\nThis type is used for all real variables, used in the Simulation. Possible alternatives: Float32, Double64, Dual Other types than Float64 or Float32 do require support of Julia types by the solver. \n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.KVec3","page":"Types","title":"KiteModels.KVec3","text":"const KVec3    = MVector{3, SimFloat}\n\nBasic 3-dimensional vector, stack allocated, mutable.\n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.SVec3","page":"Types","title":"KiteModels.SVec3","text":"const SVec3    = SVector{3, SimFloat}\n\nBasic 3-dimensional vector, stack allocated, immutable.\n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.ProfileLaw","page":"Types","title":"KiteModels.ProfileLaw","text":"@enum ProfileLaw EXP=1 LOG=2 EXPLOG=3\n\nEnumeration to describe the wind profile low that is used.\n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.AbstractKiteModel","page":"Types","title":"KiteModels.AbstractKiteModel","text":"abstract type AbstractKiteModel\n\nAll kite models must inherit from this type. All methods that are defined on this type must work with all kite models. All exported methods must work on this type. \n\n\n\n\n\n","category":"type"},{"location":"types/#Struct-KPS3","page":"Types","title":"Struct KPS3","text":"","category":"section"},{"location":"types/","page":"Types","title":"Types","text":"KPS3","category":"page"},{"location":"types/#KiteModels.KPS3","page":"Types","title":"KiteModels.KPS3","text":"mutable struct KPS3{S, T, P} <: AbstractKiteModel\n\nState of the kite power system. Parameters:\n\nS: Scalar type, e.g. SimFloat In the documentation mentioned as Any, but when used in this module it is always SimFloat and not Any.\nT: Vector type, e.g. MVector{3, SimFloat}\nP: number of points of the system, segments+1\n\nNormally a user of this package will not have to access any of the members of this type directly, use the input and output functions instead.\n\nset::KiteUtils.Settings\nReference to the settings struct Default: se()\nkcu::KitePodSimulator.KCU\nReference to the KCU struct (Kite Control Unit, type from the module KitePodSimulor Default: KCU()\ncalc_cl::Any\nFunction for calculation the lift coefficent, using a spline based on the provided value pairs. Default: Spline1D((se()).alphacl, (se()).cllist)\ncalc_cd::Any\nFunction for calculation the drag coefficent, using a spline based on the provided value pairs. Default: Spline1D((se()).alphacd, (se()).cdlist)\nv_wind::Any\nwind vector at the height of the kite Default: zeros(S, 3)\nv_wind_gnd::Any\nwind vector at reference height Default: zeros(S, 3)\nv_wind_tether::Any\nwind vector used for the calculation of the tether drag Default: zeros(S, 3)\nv_apparent::Any\napparent wind vector at the kite Default: zeros(S, 3)\nv_app_perp::Any\nDefault: zeros(S, 3)\ndrag_force::Any\nDefault: zeros(S, 3)\nlift_force::Any\nDefault: zeros(S, 3)\nsteering_force::Any\nDefault: zeros(S, 3)\nlast_force::Any\nDefault: zeros(S, 3)\nspring_force::Any\nDefault: zeros(S, 3)\ntotal_forces::Any\nDefault: zeros(S, 3)\nforce::Any\nDefault: zeros(S, 3)\nunit_vector::Any\nDefault: zeros(S, 3)\nav_vel::Any\nDefault: zeros(S, 3)\nkite_y::Any\nDefault: zeros(S, 3)\nsegment::Any\nDefault: zeros(S, 3)\nlast_tether_drag::Any\nDefault: zeros(S, 3)\nacc::Any\nDefault: zeros(S, 3)\nvec_z::Any\nDefault: zeros(S, 3)\npos_kite::Any\nDefault: zeros(S, 3)\nv_kite::Any\nDefault: zeros(S, 3)\nres1::StaticArrays.SVector{P, StaticArrays.MVector{3, Float64}} where P\nDefault: zeros(SVector{P, KVec3})\nres2::StaticArrays.SVector{P, StaticArrays.MVector{3, Float64}} where P\nDefault: zeros(SVector{P, KVec3})\npos::StaticArrays.SVector{P, StaticArrays.MVector{3, Float64}} where P\nDefault: zeros(SVector{P, KVec3})\nseg_area::Any\narea of one tether segment Default: zero(S)\nbridle_area::Any\nDefault: zero(S)\nc_spring::Any\nspring constant, depending on the length of the tether segment Default: zero(S)\nlength::Any\nDefault: 0.0\ndamping::Any\ndamping factor, depending on the length of the tether segment Default: zero(S)\narea::Any\nDefault: zero(S)\nlast_v_app_norm_tether::Any\nDefault: zero(S)\nparam_cl::Any\nlift coefficient of the kite, depending on the angle of attack Default: 0.2\nparam_cd::Any\ndrag coefficient of the kite, depending on the angle of attack Default: 1.0\nv_app_norm::Any\nDefault: zero(S)\ncor_steering::Any\nDefault: zero(S)\npsi::Any\nDefault: zero(S)\nbeta::Any\nelevation angle in radian; initial value about 70 degrees Default: 1.22\nlast_alpha::Any\nDefault: 0.1\nalpha_depower::Any\nDefault: 0.0\nt_0::Any\nrelative start time of the current time interval Default: 0.0\nv_reel_out::Any\nDefault: 0.0\nlast_v_reel_out::Any\nDefault: 0.0\nl_tether::Any\nDefault: 0.0\nrho::Any\nDefault: 0.0\ndepower::Any\nDefault: 0.0\nsteering::Any\nDefault: 0.0\ninitial_masses::StaticArrays.MVector{P, Float64} where P\ninitial masses of the point masses Default: ones(P)\nmasses::StaticArrays.MVector{P, Float64} where P\ncurrent masses, depending on the total tether length Default: ones(P)\n\n\n\n\n\n","category":"type"},{"location":"types/","page":"Types","title":"Types","text":"This file stores the state of the one point model. Only in unit tests it is allowed to access the members directly, otherwise use the input and output functions.","category":"page"}]
}
