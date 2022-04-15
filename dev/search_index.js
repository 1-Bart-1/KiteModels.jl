var documenterSearchIndex = {"docs":
[{"location":"functions/","page":"Functions","title":"Functions","text":"CurrentModule = KiteModels","category":"page"},{"location":"functions/#Introduction","page":"Functions","title":"Introduction","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"Most of the functions work on a KPS3 or KPS4 object. For this, the variable s is used. Such a variable can be created with the lines:","category":"page"},{"location":"functions/","page":"Functions","title":"Functions","text":"using KiteModels, KitePodModels\nconst s = KPS3(KCU())","category":"page"},{"location":"functions/","page":"Functions","title":"Functions","text":"Or, if you want to use the 4 point kite model:","category":"page"},{"location":"functions/","page":"Functions","title":"Functions","text":"using KiteModels, KitePodModels\nconst s = KPS4(KCU())","category":"page"},{"location":"functions/#Input-functions","page":"Functions","title":"Input functions","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"set_v_reel_out\nset_depower_steering\nset_v_wind_ground","category":"page"},{"location":"functions/#KiteModels.set_v_reel_out","page":"Functions","title":"KiteModels.set_v_reel_out","text":"set_v_reel_out(s::AKM, v_reel_out, t_0, period_time = 1.0 / s.set.sample_freq)\n\nSetter for the reel-out speed. Must be called on every timestep (before each simulation). It also updates the tether length, therefore it must be called even if v_reel_out has not changed.\n\nt_0 the start time of the next timestep relative to the start of the simulation [s]\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.set_depower_steering","page":"Functions","title":"KiteModels.set_depower_steering","text":"set_depower_steering(s::KPS3, depower, steering)\n\nSetter for the depower and steering model inputs. \n\nvalid range for steering: -1.0 .. 1.0.  \nvalid range for depower: 0 .. 1.0\n\nThis function sets the variables s.depower, s.steering and s.alpha_depower. \n\nIt takes the depower offset c0 and the dependency of the steering sensitivity from the depower settings into account.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.set_v_wind_ground","page":"Functions","title":"KiteModels.set_v_wind_ground","text":"set_v_wind_ground(s::AKM, height, v_wind_gnd=s.set.v_wind, wind_dir=0.0)\n\nSet the vector of the wind-velocity at the height of the kite. As parameter the height, the ground wind speed and the wind direction are needed. Must be called every at each timestep.\n\n\n\n\n\n","category":"function"},{"location":"functions/#Output-functions","page":"Functions","title":"Output functions","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"unstretched_length\ntether_length\nwinch_force\nspring_forces\nlift_drag\nlift_over_drag\nv_wind_kite","category":"page"},{"location":"functions/#KiteModels.unstretched_length","page":"Functions","title":"KiteModels.unstretched_length","text":"unstretched_length(s::AKM)\n\nGetter for the unstretched tether reel-out lenght (at zero force).\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.tether_length","page":"Functions","title":"KiteModels.tether_length","text":"tether_length(s::AKM)\n\nCalculate and return the real, stretched tether lenght.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.winch_force","page":"Functions","title":"KiteModels.winch_force","text":"winch_force(s::AKM)\n\nReturn the absolute value of the force at the winch as calculated during the last timestep. \n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.spring_forces","page":"Functions","title":"KiteModels.spring_forces","text":"spring_forces(s::AKM)\n\nReturn an array of the scalar spring forces of all tether segements.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.lift_drag","page":"Functions","title":"KiteModels.lift_drag","text":"lift_drag(s::AKM)\n\nReturn a tuple of the scalar lift and drag forces. \n\nExample:  \n\nlift, drag = lift_drag(kps)\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.lift_over_drag","page":"Functions","title":"KiteModels.lift_over_drag","text":"lift_over_drag(s::AKM)\n\nReturn the lift-over-drag ratio.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.v_wind_kite","page":"Functions","title":"KiteModels.v_wind_kite","text":"v_wind_kite(s::AKM)\n\nReturn the vector of the wind speed at the height of the kite.\n\n\n\n\n\n","category":"function"},{"location":"functions/#Callback-function-for-the-DAE-solver","page":"Functions","title":"Callback function for the DAE solver","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"residual!","category":"page"},{"location":"functions/#KiteModels.residual!","page":"Functions","title":"KiteModels.residual!","text":"residual!(res, yd, y::MVector{S, SimFloat}, s::KPS3, time) where S\n\nN-point tether model, one point kite at the top:\nInputs:\nState vector y   = pos1,  pos2, ... , posn,  vel1,  vel2, . .., veln,  length, v_reel_out\nDerivative   yd  = posd1, posd2, ..., posdn, veld1, veld2, ..., veldn, lengthd, v_reel_outd\nOutput:\nResidual     res = res1, res2 = vel1-posd1,  ..., veld1-acc1, ...\n\nAdditional parameters:\ns: Struct with work variables, type KPS3\nS: The dimension of the state vector\n\nThe number of the point masses of the model N = (S-2)/6, the state of each point  is represented by two 3 element vectors.\n\n\n\n\n\nresidual!(res, yd, y::MVector{S, SimFloat}, s::KPS3, time) where S\n\nN-point tether model, one point kite at the top:\nInputs:\nState vector y   = pos1, pos2, ..., posn, vel1, vel2, ..., veln\nDerivative   yd  = vel1, vel2, ..., veln, acc1, acc2, ..., accn\nOutput:\nResidual     res = res1, res2 = pos1,  ..., vel1, ...\n\nAdditional parameters:\ns: Struct with work variables, type KPS3\nS: The dimension of the state vector\n\nThe number of the point masses of the model N = S/6, the state of each point  is represented by two 3 element vectors.\n\n\n\n\n\n","category":"function"},{"location":"functions/#Environment","page":"Functions","title":"Environment","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"calc_rho\ncalc_wind_factor","category":"page"},{"location":"functions/#KiteModels.calc_rho","page":"Functions","title":"KiteModels.calc_rho","text":"calc_rho(s, height)\n\nCalculate the air densisity as function of height.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.calc_wind_factor","page":"Functions","title":"KiteModels.calc_wind_factor","text":"calc_wind_factor(s, height, profile_law=s.set.profile_law)\n\nCalculate the relative wind speed at a given height and reference height.\n\n\n\n\n\n","category":"function"},{"location":"functions/#Helper-functions","page":"Functions","title":"Helper functions","text":"","category":"section"},{"location":"functions/","page":"Functions","title":"Functions","text":"clear\nfind_steady_state\ncalc_drag\ncalc_set_cl_cd","category":"page"},{"location":"functions/#KiteModels.clear","page":"Functions","title":"KiteModels.clear","text":"clear(s::KPS3)\n\nInitialize the kite power model.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.find_steady_state","page":"Functions","title":"KiteModels.find_steady_state","text":"find_steady_state(s::KPS4, prn=false)\n\nFind an initial equilibrium, based on the inital parameters l_tether, elevation and v_reel_out.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.calc_drag","page":"Functions","title":"KiteModels.calc_drag","text":"calc_drag(s::KPS3, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)\n\nCalculate the drag of one tether segment, result stored in parameter last_tether_drag. Return the norm of the apparent wind velocity.\n\n\n\n\n\n","category":"function"},{"location":"functions/#KiteModels.calc_set_cl_cd","page":"Functions","title":"KiteModels.calc_set_cl_cd","text":"calc_set_cl_cd(s, vec_c, v_app)\n\nCalculate the lift over drag ratio as a function of the direction vector of the last tether segment, the current depower setting and the apparent wind speed. Set the calculated CL and CD values in the struct s. \n\n\n\n\n\n","category":"function"},{"location":"examples/","page":"Examples","title":"Examples","text":"CurrentModule = KiteModels","category":"page"},{"location":"examples/#Examples","page":"Examples","title":"Examples","text":"","category":"section"},{"location":"examples/#Create-a-test-project","page":"Examples","title":"Create a test project","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"mkdir test\ncd test\njulia --project","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"and add KiteModels to the project:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"]activate .\nadd KiteUtils\nadd KitePodSimulator\nadd KiteModels\n<BACKSPACE>","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"finally, copy the default configuration files to your new project:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using KiteUtils\ncopy_settings()","category":"page"},{"location":"examples/#Plotting-the-initial-state","page":"Examples","title":"Plotting the initial state","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"First an instance of the model of the kite control unit (KCU) is created which is needed by the Kite Power System model KPS3. Then we create a kps instance, passing the kcu model as parameter. We need to declare these variables as const to achieve a decent performance.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using KiteModels\nusing KitePodModels\nconst kcu = KCU()\nconst kps = KPS3(kcu)","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Then we call the function findsteadystate which uses a non-linear solver to find the solution for a given elevation angle, reel-out speed and wind speed. ","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"find_steady_state(kps, true)","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"To plot the result in 2D we extract the vectors of the x and z coordinates of the tether particles with a for loop:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"x = Float64[] \nz = Float64[]\nfor i in 1:length(kps.pos)\n     push!(x, kps.pos[i][1])\n     push!(z, kps.pos[i][3])\nend","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"And finally we plot the postion of the particles in the x-z plane. When you type using Plots you will be ask if you want to install the Plots package. Just press \\<ENTER\\> and it gets installed.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using Plots\nplot(x,z, xlabel=\"x [m]\", ylabel=\"z [m]\", legend=false)\nplot!(x, z, seriestype = :scatter)","category":"page"},{"location":"examples/#Inital-State","page":"Examples","title":"Inital State","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"(Image: Initial State)","category":"page"},{"location":"examples/#Print-other-model-outputs","page":"Examples","title":"Print other model outputs","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"Print the vector of the positions of the particles:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> kps.pos\n7-element StaticArrays.SVector{7, StaticArrays.MVector{3, Float64}} with indices SOneTo(7):\n [0.0, 1.0e-6, 0.0]\n [26.957523083220014, 1.0e-6, 59.597492705934215]\n [51.97089867461361, 1.0e-6, 120.03746428611659]\n [75.01425347614648, 1.0e-6, 181.25636723731242]\n [96.06812033613873, 1.0e-6, 243.18840457807227]\n [115.11961850809006, 1.0e-6, 305.76616644603797]\n [132.79574786242222, 1.0e-6, 368.747001395149]","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Print the unstretched and and stretched tether length:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> unstretched_length(kps)\n392.0\n\njulia> tether_length(kps)\n392.4751313610764","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Print the force at the winch (groundstation, in Newton) and at each tether segment:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> winch_force(kps)\n728.5567740002092\n\njulia> spring_forces(kps)\n6-element Vector{Float64}:\n 728.4833579505422\n 734.950422647022\n 741.5051811137938\n 748.1406855651342\n 754.8497626815621\n 761.6991795967015","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"The force increases when going upwards because the kite not only experiances the winch force, but in addition the weight of the tether.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Print the lift and drag forces of the kite (in Newton) and the lift over drag ratio:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> lift, drag = lift_drag(kps)\n(888.5714473490408, 188.25226817881344)\n\njulia> lift_over_drag(kps)\n4.720110179522627","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"Print the wind speed vector at the kite:","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"julia> v_wind_kite(kps)\n3-element StaticArrays.MVector{3, Float64} with indices SOneTo(3):\n 13.308227837486344\n  0.0\n  0.0","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = KiteModels","category":"page"},{"location":"#KiteModels","page":"Home","title":"KiteModels","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for the package KiteModels.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Download Julia 1.6 or later, if you haven't already. You can add KiteModels from  Julia's package manager, by typing ","category":"page"},{"location":"","page":"Home","title":"Home","text":"] add KiteModels","category":"page"},{"location":"","page":"Home","title":"Home","text":"at the Julia prompt.","category":"page"},{"location":"","page":"Home","title":"Home","text":"If you are using Windows, it is suggested to install git and bash, too. This is explained for example here: Julia on Windows .","category":"page"},{"location":"#Provides","page":"Home","title":"Provides","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The type AbstractKiteModel with the implementation KPS3 and the residual! function for a DAE solver, representing the model. Other kite models can be added inside or outside of this package by implementing the non-generic methods required for an AbstractKiteModel.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Additional functions to provide inputs and outputs of the model on each time step. Per time step the residual! function is called as many times as needed to find the solution at the end of the time step. The formulas are based on basic physics and aerodynamics and can be quite simple because a differential algebraic notation is used.","category":"page"},{"location":"","page":"Home","title":"Home","text":"(Image: Four point kite power system model)","category":"page"},{"location":"#Further-reading","page":"Home","title":"Further reading","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"These models are described in detail in Dynamic Model of a Pumping Kite Power System.","category":"page"},{"location":"#See-also","page":"Home","title":"See also","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Research Fechner for the scientic background of this code\nThe application KiteViewer\nthe package KiteUtils\nthe package KitePodSimulator","category":"page"},{"location":"","page":"Home","title":"Home","text":"Author: Uwe Fechner (uwe.fechner.msc@gmail.com)","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"CurrentModule = KiteModels","category":"page"},{"location":"parameters/#Configuration","page":"Parameters","title":"Configuration","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"To configure the parameters of the kite models, edit the file data/settings.yaml , or create a copy under a different name and change the name of the active configuration in the file data/system.yaml .","category":"page"},{"location":"parameters/#Parameters","page":"Parameters","title":"Parameters","text":"","category":"section"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"The following parameters are used by this package:","category":"page"},{"location":"parameters/","page":"Parameters","title":"Parameters","text":"system:\n    sample_freq:   20              # sample frequency in Hz\n\ninitial:\n    l_tether: 392.0        # initial tether length       [m]\n    elevation: 70.7        # initial elevation angle   [deg]\n    v_reel_out: 0.0        # initial reel out speed    [m/s]\n\nsteering:\n    c0:       0.0          # steering offset   -0.0032           [-]\n    c_s:      2.59         # steering coefficient one point model\n    c2_cor:   0.93         # correction factor one point model\n    k_ds:     1.5          # influence of the depower angle on the steering sensitivity\n\ndepower:\n    alpha_d_max:    31.0   # max depower angle                            [deg]\n    \nkite:\n    model: \"data/kite.obj\" # 3D model of the kite\n    mass:  6.2             # kite mass incl. sensor unit [kg]\n    area: 10.18            # projected kite area         [m²]\n    rel_side_area: 30.6    # relative side area           [%]\n    height: 2.23           # height of the kite           [m]\n    alpha_cl:  [-180.0, -160.0, -90.0, -20.0, -10.0,  -5.0,  0.0, 20.0, 40.0, 90.0, 160.0, 180.0]\n    cl_list:   [   0.0,    0.5,   0.0,  0.08, 0.125,  0.15,  0.2,  1.0,  1.0,  0.0,  -0.5,   0.0]\n    alpha_cd:  [-180.0, -170.0, -140.0, -90.0, -20.0, 0.0, 20.0, 90.0, 140.0, 170.0, 180.0]\n    cd_list:   [   0.5,    0.5,    0.5,   1.0,   0.2, 0.1,  0.2,  1.0,   0.5,   0.5,   0.5]\n    \nbridle:\n    d_line:    2.5         # bridle line diameter                  [mm]\n    l_bridle: 33.4         # sum of the lengths of the bridle lines [m]\n    h_bridle:  4.9         # height of bridle                       [m]\n\nkcu:\n    kcu_mass: 8.4                # mass of the kite control unit   [kg]\n\ntether:\n    d_tether:  4           # tether diameter                 [mm]\n    cd_tether: 0.958       # drag coefficient of the tether\n    damping: 473.0         # unit damping coefficient        [Ns]\n    c_spring: 614600.0     # unit spring constant coefficient [N]\n    rho_tether:  724.0     # density of Dyneema           [kg/m³]\n\nenvironment:\n    v_wind: 9.51             # wind speed at reference height          [m/s]\n    h_ref:  6.0              # reference height for the wind speed     [m]\n\n    rho_0:  1.225            # air density at the ground or zero       [kg/m³]\n    alpha:  0.08163          # exponent of the wind profile law\n    z0:     0.0002           # surface roughness                       [m]\n    profile_law: 3           # 1=EXP, 2=LOG, 3=EXPLOG","category":"page"},{"location":"types/#Exported-Types","page":"Types","title":"Exported Types","text":"","category":"section"},{"location":"types/","page":"Types","title":"Types","text":"CurrentModule = KiteModels","category":"page"},{"location":"types/#Basic-types","page":"Types","title":"Basic types","text":"","category":"section"},{"location":"types/","page":"Types","title":"Types","text":"SimFloat\nKVec3\nSVec3\nProfileLaw\nAbstractKiteModel\nAKM","category":"page"},{"location":"types/#KiteModels.SimFloat","page":"Types","title":"KiteModels.SimFloat","text":"const SimFloat = Float64\n\nThis type is used for all real variables, used in the Simulation. Possible alternatives: Float32, Double64, Dual Other types than Float64 or Float32 do require support of Julia types by the solver. \n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.KVec3","page":"Types","title":"KiteModels.KVec3","text":"const KVec3    = MVector{3, SimFloat}\n\nBasic 3-dimensional vector, stack allocated, mutable.\n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.SVec3","page":"Types","title":"KiteModels.SVec3","text":"const SVec3    = SVector{3, SimFloat}\n\nBasic 3-dimensional vector, stack allocated, immutable.\n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.ProfileLaw","page":"Types","title":"KiteModels.ProfileLaw","text":"ProfileLaw\n\nEnumeration to describe the wind profile low that is used.\n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.AbstractKiteModel","page":"Types","title":"KiteModels.AbstractKiteModel","text":"abstract type AbstractKiteModel\n\nAll kite models must inherit from this type. All methods that are defined on this type must work with all kite models. All exported methods must work on this type. \n\n\n\n\n\n","category":"type"},{"location":"types/#KiteModels.AKM","page":"Types","title":"KiteModels.AKM","text":"const AKM = AbstractKiteModel\n\nShort alias for the AbstractKiteModel. \n\n\n\n\n\n","category":"type"},{"location":"types/#Struct-KPS3","page":"Types","title":"Struct KPS3","text":"","category":"section"},{"location":"types/","page":"Types","title":"Types","text":"KPS3","category":"page"},{"location":"types/#KiteModels.KPS3","page":"Types","title":"KiteModels.KPS3","text":"mutable struct KPS3{S, T, P} <: AbstractKiteModel\n\nState of the kite power system. Parameters:\n\nS: Scalar type, e.g. SimFloat In the documentation mentioned as Any, but when used in this module it is always SimFloat and not Any.\nT: Vector type, e.g. MVector{3, SimFloat}\nP: number of points of the system, segments+1\n\nNormally a user of this package will not have to access any of the members of this type directly, use the input and output functions instead.\n\nset::KiteUtils.Settings\nReference to the settings struct Default: se()\nkcu::KitePodModels.KCU\nReference to the KCU struct (Kite Control Unit, type from the module KitePodSimulor Default: KCU()\niter::Int64\nIteration Default: 0\ncalc_cl::Any\nFunction for calculation the lift coefficent, using a spline based on the provided value pairs. Default: Spline1D((se()).alphacl, (se()).cllist)\ncalc_cd::Any\nFunction for calculation the drag coefficent, using a spline based on the provided value pairs. Default: Spline1D((se()).alphacd, (se()).cdlist)\nv_wind::Any\nwind vector at the height of the kite Default: zeros(S, 3)\nv_wind_gnd::Any\nwind vector at reference height Default: zeros(S, 3)\nv_wind_tether::Any\nwind vector used for the calculation of the tether drag Default: zeros(S, 3)\nv_apparent::Any\napparent wind vector at the kite Default: zeros(S, 3)\nv_app_perp::Any\nvector, perpendicular to vapparent; output of calcdrag Default: zeros(S, 3)\ndrag_force::Any\ndrag force of kite and bridle; output of calcaeroforces Default: zeros(S, 3)\nlift_force::Any\nlift force of the kite; output of calcaeroforces Default: zeros(S, 3)\nsteering_force::Any\nsteering force acting on the kite; output of calcaeroforces Default: zeros(S, 3)\nlast_force::Any\nDefault: zeros(S, 3)\nspring_force::Any\nspring force of the current tether segment, output of calc_res Default: zeros(S, 3)\ntotal_forces::Any\nDefault: zeros(S, 3)\nforce::Any\nsum of spring and drag forces acting on the current segment, output of calc_res Default: zeros(S, 3)\nunit_vector::Any\nunit vector in the direction of the current tether segment, output of calc_res Default: zeros(S, 3)\nav_vel::Any\naverage velocity of the current tether segment, output of calc_res Default: zeros(S, 3)\nkite_y::Any\ny-vector of the kite fixed referense frame, output of calcaeroforces Default: zeros(S, 3)\nsegment::Any\nDefault: zeros(S, 3)\nlast_tether_drag::Any\nDefault: zeros(S, 3)\nacc::Any\nDefault: zeros(S, 3)\nvec_z::Any\nDefault: zeros(S, 3)\nres1::StaticArrays.SVector{P, StaticArrays.MVector{3, Float64}} where P\nDefault: zeros(SVector{P, KVec3})\nres2::StaticArrays.SVector{P, StaticArrays.MVector{3, Float64}} where P\nDefault: zeros(SVector{P, KVec3})\npos::StaticArrays.SVector{P, StaticArrays.MVector{3, Float64}} where P\nDefault: zeros(SVector{P, KVec3})\nseg_area::Any\narea of one tether segment Default: zero(S)\nbridle_area::Any\nDefault: zero(S)\nc_spring::Any\nspring constant, depending on the length of the tether segment Default: zero(S)\nsegment_length::Any\nunstressed segment length [m] Default: 0.0\ndamping::Any\ndamping factor, depending on the length of the tether segment Default: zero(S)\narea::Any\nDefault: zero(S)\nlast_v_app_norm_tether::Any\nDefault: zero(S)\nparam_cl::Any\nlift coefficient of the kite, depending on the angle of attack Default: 0.2\nparam_cd::Any\ndrag coefficient of the kite, depending on the angle of attack Default: 1.0\nv_app_norm::Any\nDefault: zero(S)\ncor_steering::Any\nDefault: zero(S)\npsi::Any\nazimuth angle in radian; inital value is zero Default: zero(S)\nbeta::Any\nelevation angle in radian; initial value about 70 degrees Default: deg2rad((se()).elevation)\nlast_alpha::Any\nDefault: 0.1\nalpha_depower::Any\nDefault: 0.0\nt_0::Any\nrelative start time of the current time interval Default: 0.0\nv_reel_out::Any\nDefault: 0.0\nlast_v_reel_out::Any\nDefault: 0.0\nl_tether::Any\nDefault: 0.0\nrho::Any\nDefault: 0.0\ndepower::Any\nDefault: 0.0\nsteering::Any\nDefault: 0.0\nstiffness_factor::Any\nDefault: 1.0\nlog_href_over_z0::Any\nDefault: log((se()).h_ref / (se()).z0)\ninitial_masses::StaticArrays.MVector{P, S} where {S, P}\ninitial masses of the point masses Default: ones(P)\nmasses::StaticArrays.MVector{P, S} where {S, P}\ncurrent masses, depending on the total tether length Default: ones(P)\n\n\n\n\n\n","category":"type"},{"location":"types/","page":"Types","title":"Types","text":"This struct stores the state of the one point model. Only in unit tests it is allowed to access the members directly, otherwise use the input and output functions.","category":"page"}]
}
