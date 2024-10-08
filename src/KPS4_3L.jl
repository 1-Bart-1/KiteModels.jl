#= MIT License

Copyright (c) 2024 Uwe Fechner and Bart van de Lint

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

#= Model of a kite-power system in implicit form: residual = f(y, yd)

This model implements a 3D mass-spring system with reel-out. It uses six tether segments (the number can be
configured in the file data/settings.yaml). The kite is modelled using 4 point masses and 3*n aerodynamic 
surfaces. The spring constant and the damping decrease with the segment length. The aerodynamic kite forces
are acting on three of the four kite point masses. 

Four point kite model, included from KiteModels.jl.

Scientific background: http://arxiv.org/abs/1406.6218 =#

# Array of connections of bridlepoints.
# First point, second point, unstressed length.
const SPRINGS_INPUT_3L = [1.      4.  -1. # s1: E, A
                        1.      2.  -1. # s2, E, C
                        1.      3.  -1. # s3, E, D
                        2.      3.  -1. # s4, C, D
                        2.      4.  -1. # s5, C, A
                        3.      4.  -1. # s6, D, A
                        ]
# E = 1, C = 2, D = 3, A = 4
# E = segments*3+1, C = segments*3+2, D = segments*3+3, A = segments*3+4


const KITE_SPRINGS_3L = 6
const KITE_PARTICLES_3L = 4
const KITE_ANGLE_3L = 0.0

"""
    mutable struct KPS4_3L{S, T, P, Q, SP} <: AbstractKiteModel

State of the kite power system, using a 3 point kite model and three steering lines to the ground. Parameters:
- S: Scalar type, e.g. SimFloat
  In the documentation mentioned as Any, but when used in this module it is always SimFloat and not Any.
- T: Vector type, e.g. MVector{3, SimFloat}
- P: number of points of the system, segments+3
- Q: number of springs in the system, P-1
- SP: struct type, describing a spring
Normally a user of this package will not have to access any of the members of this type directly,
use the input and output functions instead.

$(TYPEDFIELDS)
"""
@with_kw mutable struct KPS4_3L{S, T, P, Q, SP} <: AbstractKiteModel
    "Reference to the settings struct"
    set::Settings
    "Reference to the atmospheric model as implemented in the package AtmosphericModels"
    am::AtmosphericModel = AtmosphericModel()
    "Function for calculation the lift coefficent, using a spline based on the provided value pairs."
    calc_cl = Spline1D(se().alpha_cl, se().cl_list)
    "Function for calculation the drag coefficent, using a spline based on the provided value pairs."
    calc_cd = Spline1D(se().alpha_cd, se().cd_list)
    "Reference to the motor models as implemented in the package WinchModels. index 1: middle motor, index 2: left motor, index 3: right motor"
    motors::SVector{3, AbstractWinchModel}
    "Iterations, number of calls to the function residual!"
    iter:: Int64 = 0
    "wind vector at the height of the kite" 
    v_wind::T =           zeros(S, 3)
    "wind vector at reference height" 
    v_wind_gnd::T =       zeros(S, 3)
    "wind vector used for the calculation of the tether drag"
    v_wind_tether::T =    zeros(S, 3)
    "apparent wind vector at the kite"
    v_apparent::T =       zeros(S, 3)
    "drag force of kite and bridle; output of calc_aero_forces!"
    drag_force::T =       zeros(S, 3)
    "lift force of the kite; output of calc_aero_forces!"
    lift_force::T =       zeros(S, 3)    
    "spring force of the current tether segment, output of calc_particle_forces!"
    spring_force::T =     zeros(S, 3)
    "last winch force"
    winch_forces::SVector{3,T} = [zeros(S, 3) for _ in 1:3]
    "a copy of the residual one (pos,vel) for debugging and unit tests"    
    res1::SVector{P, T} = zeros(SVector{P, T})
    "a copy of the residual two (vel,acc) for debugging and unit tests"
    res2::SVector{P, T} = zeros(SVector{P, T})
    "a copy of the actual positions as output for the user"
    pos::SVector{P, T} = zeros(SVector{P, T})
    stable_pos::SVector{P, T} = zeros(SVector{P, T})
    vel::SVector{P, T} = zeros(SVector{P, T})
    posd::SVector{P, T} = zeros(SVector{P, T})
    veld::SVector{P, T} = zeros(SVector{P, T})
    "velocity vector of the kite"
    vel_kite::T =          zeros(S, 3)
    steering_vel::T =          zeros(S, 3)
    "unstressed segment lengths of the three tethers [m]"
    segment_lengths::T =           zeros(S, 3)
    "lift coefficient of the kite, depending on the angle of attack"
    param_cl::S =         0.2
    "drag coefficient of the kite, depending on the angle of attack"
    param_cd::S =         1.0
    "azimuth angle in radian; inital value is zero"
    psi::S =              zero(S)
    "relative start time of the current time interval"
    t_0::S =               0.0
    "reel out speed of the winch"
    reel_out_speeds::T =        zeros(S, 3)
    "unstretched tether length"
    tether_lengths::T =          zeros(S, 3)
    "lengths of the connections of the steering tethers to the kite"
    steering_pos::MVector{2, S} =      zeros(S, 2)
    "air density at the height of the kite"
    rho::S =               0.0
    "multiplier for the stiffniss of tether and bridle"
    stiffness_factor::S =  1.0
    "initial masses of the point masses"
    initial_masses::MVector{P, S} = ones(P)
    "current masses, depending on the total tether length"
    masses::MVector{P, S}         = zeros(P)
    "vector of the springs, defined as struct"
    springs::MVector{Q, SP}       = zeros(SP, Q)
    "vector of the forces, acting on the particles"
    forces::SVector{P, T} = zeros(SVector{P, T})
    "synchronous speed or torque of the motor/ generator"
    set_values::KVec3  = zeros(KVec3)
    torque_control::Bool = false
    "x vector of kite reference frame"
    e_x::T =                 zeros(S, 3)
    "y vector of kite reference frame"
    e_y::T =                 zeros(S, 3)
    "z vector of kite reference frame"
    e_z::T =                 zeros(S, 3)
    e_r::T =                 zeros(S, 3)
    "Point number of E"
    num_E::Int64 =           0
    "Point number of C"
    num_C::Int64 =           0
    "Point number of D"
    num_D::Int64 =           0
    "Point number of A"

    "mtk variables"
    mtk::Bool = false

    set_values_idx::Union{ModelingToolkit.ParameterIndex, Nothing} = nothing
    v_wind_gnd_idx::Union{ModelingToolkit.ParameterIndex, Nothing} = nothing
    stiffness_factor_idx::Union{ModelingToolkit.ParameterIndex, Nothing} = nothing
    v_wind_idx::Union{ModelingToolkit.ParameterIndex, Nothing} = nothing
    prob::Union{OrdinaryDiffEqCore.ODEProblem, Nothing} = nothing
    get_pos::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_steering_pos::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_line_acc::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_kite_vel::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_winch_forces::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_tether_lengths::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_tether_speeds::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_L_C::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_L_D::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_D_C::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing
    get_D_D::Union{SymbolicIndexingInterface.MultipleGetters, SymbolicIndexingInterface.TimeDependentObservedFunction, Nothing} = nothing

    half_drag_force::SVector{P, T} = zeros(SVector{P, T})

    "residual variables"
    num_A::Int64 =           0
    L_C::T = zeros(S, 3)
    L_D::T = zeros(S, 3)
    D_C::T = zeros(S, 3)
    D_D::T = zeros(S, 3)
    F_steering_c::T = zeros(S, 3)
    F_steering_d::T = zeros(S, 3)
    dL_dα::T = zeros(S, 3)
    dD_dα::T = zeros(S, 3)
    v_cx::T = zeros(S, 3)
    v_dx::T = zeros(S, 3)
    v_dy::T = zeros(S, 3)
    v_dz::T = zeros(S, 3)
    v_cy::T = zeros(S, 3)
    v_cz::T = zeros(S, 3)
    v_kite::T = zeros(S, 3)
    v_a::T = zeros(S, 3)
    e_drift::T = zeros(S, 3)
    v_a_xr::T = zeros(S, 3)
    E_c::T = zeros(S, 3)
    F::T = zeros(S, 3)
    y_lc::S = 0.0
    y_ld::S = 0.0
    δ_left::S = 0.0
    δ_right::S = 0.0
    α_l::S = 0.0
    α_r::S = 0.0
    distance_c_e::S = 0
end

"""
    clear!(s::KPS4_3L)

Initialize the kite power model.
"""
function clear!(s::KPS4_3L)
    s.iter = 0
    s.t_0 = 0.0                              # relative start time of the current time interval
    s.reel_out_speeds = zeros(3)
    # s.last_reel_out_speeds = zeros(3)
    s.v_wind_gnd    .= [s.set.v_wind, 0, 0]    # wind vector at reference height
    s.v_wind_tether .= [s.set.v_wind, 0, 0]
    s.v_apparent    .= [s.set.v_wind, 0, 0]
    height = sin(deg2rad(s.set.elevation)) * (s.set.l_tether)
    s.v_wind .= s.v_wind_gnd * calc_wind_factor(s.am, height)

    s.tether_lengths .= [s.set.l_tether for _ in 1:3]
    s.α_l = π/2 - s.set.min_steering_line_distance/(2*s.set.radius)
    s.α_r = π/2 + s.set.min_steering_line_distance/(2*s.set.radius)

    s.segment_lengths .= s.tether_lengths ./ s.set.segments
    s.num_E = s.set.segments*3+3
    s.num_C = s.set.segments*3+3+1
    s.num_D = s.set.segments*3+3+2
    s.num_A = s.set.segments*3+3+3
    init_masses!(s)
    init_springs!(s)
    for i in 1:s.num_A
        s.forces[i] .= zeros(3)
    end
    s.drag_force .= [0.0, 0, 0]
    s.lift_force .= [0.0, 0, 0]
    s.rho = s.set.rho_0
    s.calc_cl = Spline1D(s.set.alpha_cl, s.set.cl_list)
    s.calc_cd = Spline1D(s.set.alpha_cd, s.set.cd_list) 
end

function KPS4_3L(kcu::KCU)
    set = kcu.set
    if set.winch_model == "TorqueControlledMachine"
        s = KPS4_3L{SimFloat, KVec3, set.segments*3+2+KITE_PARTICLES, set.segments*3+KITE_SPRINGS_3L, SP}(set=kcu.set, motors=[TorqueControlledMachine(set) for _ in 1:3])
        println("Using torque control.")
    else
        s = KPS4_3L{SimFloat, KVec3, set.segments*3+2+KITE_PARTICLES, set.segments*3+KITE_SPRINGS_3L, SP}(set=kcu.set, motors=[AsyncMachine(set) for _ in 1:3])
    end
    s.num_E = s.set.segments*3+3
    s.num_C = s.set.segments*3+3+1
    s.num_D = s.set.segments*3+3+2
    s.num_A = s.set.segments*3+3+3     
    clear!(s)
    return s
end

function calc_kite_ref_frame!(s::KPS4_3L, E, C, D)
    P_c = 0.5 .* (C+D)
    s.e_y .= normalize(C - D)
    s.e_z .= normalize(E - P_c)
    s.e_x .= cross(s.e_y, s.e_z)
    return nothing
end

function calc_tether_elevation(s::KPS4_3L)
    KiteUtils.calc_elevation(s.pos[6])
end

function calc_tether_azimuth(s::KPS4_3L)
    KiteUtils.azimuth_east(s.pos[6])
end

function update_sys_state!(ss::SysState, s::KPS4_3L, zoom=1.0)
    ss.time = s.t_0
    pos = s.pos
    P = length(pos)
    for i in 1:P
        ss.X[i] = pos[i][1] * zoom
        ss.Y[i] = pos[i][2] * zoom
        ss.Z[i] = pos[i][3] * zoom
    end
    ss.orient .= calc_orient_quat(s)
    ss.elevation = calc_elevation(s)
    ss.azimuth = calc_azimuth(s)
    ss.force = winch_force(s)[3]
    ss.heading = calc_heading(s)
    ss.course = calc_course(s)
    ss.v_app = norm(s.v_apparent)
    ss.l_tether = s.tether_lengths[3]
    ss.v_reelout = s.reel_out_speeds[3]
    ss.depower = 100 - ((s.δ_left + s.δ_right)/2) / ((s.set.middle_length + s.set.tip_length)/2) * 100
    ss.steering = (s.δ_right - s.δ_left) / ((s.set.middle_length + s.set.tip_length)/2) * 100
    ss.vel_kite .= s.vel_kite
    nothing
end

function SysState(s::KPS4_3L, zoom=1.0)
    pos = s.pos
    P = length(pos)
    X = zeros(MVector{P, MyFloat})
    Y = zeros(MVector{P, MyFloat})
    Z = zeros(MVector{P, MyFloat})
    for i in 1:P
        X[i] = pos[i][1] * zoom
        Y[i] = pos[i][2] * zoom
        Z[i] = pos[i][3] * zoom
    end
    
    orient = MVector{4, Float32}(calc_orient_quat(s))
    elevation = calc_elevation(s)
    azimuth = calc_azimuth(s)
    forces = winch_force(s)
    heading = calc_heading(s)
    course = calc_course(s)
    v_app_norm = norm(s.v_apparent)
    t_sim = 0
    depower = 100 - ((s.δ_left + s.δ_right)/2) / ((s.set.middle_length + s.set.tip_length)/2) * 100
    steering = (s.δ_right - s.δ_left) / ((s.set.middle_length + s.set.tip_length)/2) * 100
    KiteUtils.SysState{P}(s.t_0, t_sim, 0, 0, orient, elevation, azimuth, s.tether_lengths[3], s.reel_out_speeds[3], forces[3], depower, steering, 
                          heading, course, v_app_norm, s.vel_kite, X, Y, Z, 
                          0, 0, 0, 0, 
                          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
end

function reset_sim!(s::KPS4_3L; stiffness_factor=0.035)
    if s.mtk
        clear!(s)
        s.stiffness_factor = stiffness_factor  
        dt = 1/s.set.sample_freq
        integrator = OrdinaryDiffEqCore.init(s.prob, KenCarp4(autodiff=false); dt, abstol=s.set.abs_tol, reltol=s.set.rel_tol, save_on=false)
        update_pos!(s, integrator)
        return integrator
    end
    println("Not an mtk model. Returning nothing.")
    return nothing
end

function next_step!(s::KPS4_3L, integrator; set_values=zeros(KVec3), v_wind_gnd=s.set.v_wind, wind_dir=0.0, dt=1/s.set.sample_freq)
    s.iter = 0
    set_v_wind_ground!(s, calc_height(s), v_wind_gnd, wind_dir)
    s.set_values .= set_values
    if s.mtk
        integrator.ps[s.set_values_idx] .= s.set_values
        integrator.ps[s.v_wind_gnd_idx] .= s.v_wind_gnd
        integrator.ps[s.v_wind_idx] .= s.v_wind
        integrator.ps[s.stiffness_factor_idx] = s.stiffness_factor
    end
    s.t_0 = integrator.t
    if s.mtk
        OrdinaryDiffEqCore.step!(integrator, dt, true)
        update_pos!(s, integrator)
    elseif s.set.solver == "IDA"
        Sundials.step!(integrator, dt, true)
    else
        OrdinaryDiffEqCore.step!(integrator, dt, true)
    end
    if s.stiffness_factor < 1.0
        s.stiffness_factor+=0.01
        if s.stiffness_factor > 1.0
            s.stiffness_factor = 1.0
        end
    end
    integrator.t
end

function calc_pre_tension(s::KPS4_3L)
    forces = spring_forces(s)
    avg_force = 0.0
    for i in 1:s.num_A
        avg_force += forces[i]
    end
    avg_force /= s.num_A
    res = avg_force/s.set.c_spring
    if res < 0.0 res = 0.0 end
    if isnan(res) res = 0.0 end
    return res + 1.0
end

"""
    unstretched_length(s::KPS4_3L)

Getter for the unstretched tether reel-out lenght (at zero force).
"""
function unstretched_length(s::KPS4_3L) s.tether_lengths[3] end

"""
    tether_length(s::KPS4_3L)

Calculate and return the real, stretched tether lenght.
"""
function tether_length(s::KPS4_3L)
    length = 0.0
    for i in 3:3:s.num_E-3
        length += norm(s.pos[i+3] - s.pos[i])
    end
    return length
end

"""
    calc_aero_forces!(s::KPS4_3L, pos, vel)

Calculates the aerodynamic forces acting on the kite particles.

Parameters:
- pos:              vector of the particle positions
- vel:              vector of the particle velocities
- rho:              air density [kg/m^3]
- rel_depower:      value between  0.0 and  1.0
- alpha_depower:    depower angle [degrees]
- rel_steering:     value between -1.0 and +1.0

Updates the vector s.forces of the first parameter.
"""
function calc_aero_forces!(s::KPS4_3L, pos::SVector{N, KVec3}, vel::SVector{N, KVec3}) where N
    n = s.set.aero_surfaces

    s.δ_left = (pos[s.num_E-2].-pos[s.num_C]) ⋅ s.e_z
    s.δ_right = (pos[s.num_E-1].-pos[s.num_D]) ⋅ s.e_z
    
    s.E_c .= pos[s.num_E] .+ s.e_z .* (-s.set.bridle_center_distance + s.set.radius) # in the aero calculations, E_c is the center of the circle shape on which the kite lies
    s.v_cx .= dot(vel[s.num_C], s.e_x).*s.e_x
    s.v_dx .= dot(vel[s.num_D], s.e_x).*s.e_x
    s.v_dy .= dot(vel[s.num_D], s.e_y).*s.e_y
    s.v_dz .= dot(vel[s.num_D], s.e_z).*s.e_z
    s.v_cy .= dot(vel[s.num_C], s.e_y).*s.e_y
    s.v_cz .= dot(vel[s.num_C], s.e_z).*s.e_z
    s.y_lc = norm(pos[s.num_C] .- 0.5 .* (pos[s.num_C].+pos[s.num_D]))
    s.y_ld = -norm(pos[s.num_D] .- 0.5 .* (pos[s.num_C].+pos[s.num_D]))

    # Calculate the lift and drag
    α_0 = pi/2 - s.set.width/2/s.set.radius
    α_middle = pi/2
    dα = (α_middle - α_0) / n
    α = zero(SimFloat)
    s.L_C .= SVec3(zeros(SVec3))
    s.L_D .= SVec3(zeros(SVec3))
    s.D_C .= SVec3(zeros(SVec3))
    s.D_D .= SVec3(zeros(SVec3))
    # println("calculating aero forces...")
    @inbounds @simd for i in 1:n*2
        if i <= n
            α = α_0 + -dα/2 + i*dα
        else
            α = pi - (α_0 + -dα/2 + (i-n)*dα)
        end

        s.F .= s.E_c .+ s.e_y.*cos(α).*s.set.radius .- s.e_z.*sin(α).*s.set.radius
        s.e_r .= (s.E_c .- s.F)./norm(s.E_c .- s.F)
        y_l = cos(α) * s.set.radius
        if α < π/2
            s.v_kite .= ((s.v_cx .- s.v_dx)./(s.y_lc .- s.y_ld).*(y_l .- s.y_ld) .+ s.v_dx) .+ s.v_cy .+ s.v_cz
        else
            s.v_kite .= ((s.v_cx .- s.v_dx)./(s.y_lc .- s.y_ld).*(y_l .- s.y_ld) .+ s.v_dx) .+ s.v_dy .+ s.v_dz
        end
        s.v_a .= s.v_wind .- s.v_kite
        s.e_drift .= (s.e_r × s.e_x)
        s.v_a_xr .= s.v_a .- (s.v_a ⋅ s.e_drift) .* s.e_drift
        if α < π/2
            kite_length = (s.set.tip_length + (s.set.middle_length-s.set.tip_length)*α*s.set.radius/(0.5*s.set.width))
        else
            kite_length = (s.set.tip_length + (s.set.middle_length-s.set.tip_length)*(π-α)*s.set.radius/(0.5*s.set.width))
        end
        if α < s.α_l
            d = s.δ_left
        elseif α > s.α_r
            d = s.δ_right
        else
            d = (s.δ_right - s.δ_left) / (s.α_r - s.α_l) * (α - s.α_l) + (s.δ_left)
        end
        aoa = π - acos2(normalize(s.v_a_xr) ⋅ s.e_x) + asin(clamp(d/kite_length, -1.0, 1.0))
        s.dL_dα .= 0.5*s.rho*(norm(s.v_a_xr))^2*s.set.radius*kite_length*rad_cl(aoa) .* normalize(s.v_a_xr × s.e_drift)
        s.dD_dα .= 0.5*s.rho*norm(s.v_a_xr)*s.set.radius*kite_length*rad_cd(aoa) .* s.v_a_xr # the sideways drag cannot be calculated with the C_d formula
        if i <= n
            s.L_C .+= s.dL_dα .* dα
            s.D_C .+= s.dD_dα .* dα
        else 
            s.L_D .+= s.dL_dα .* dα
            s.D_D .+= s.dD_dα .* dα
        end
    end
    s.lift_force .= s.L_C .+ s.L_D
    s.drag_force .= s.D_C .+ s.D_D
    
    s.F_steering_c .= ((0.2 * (s.L_C ⋅ -s.e_z)) .* -s.e_z)
    s.F_steering_d .= ((0.2 * (s.L_D ⋅ -s.e_z)) .* -s.e_z)
    s.forces[s.num_C] .+= (s.L_C .+ s.D_C) .- s.F_steering_c
    s.forces[s.num_D] .+= (s.L_D .+ s.D_D) .- s.F_steering_d
    s.forces[s.num_E-2] .+= s.F_steering_c
    s.forces[s.num_E-1] .+= s.F_steering_d
    return nothing
end

""" 
    calc_particle_forces!(s::KPS4_3L, pos1, pos2, vel1, vel2, spring, d_tether, rho, i)

Calculate the drag force and spring force of the tether segment, defined by the parameters pos1, pos2, vel1 and vel2
and distribute it equally on the two particles, that are attached to the segment.
The result is stored in the array s.forces. 
"""
@inline function calc_particle_forces!(s::KPS4_3L, pos1, pos2, vel1, vel2, spring, d_tether, rho, i)
    l_0 = spring.length # Unstressed length
    k = spring.c_spring * s.stiffness_factor  # Spring constant
    c = spring.damping                        # Damping coefficient    
    segment = pos1 - pos2
    rel_vel = vel1 - vel2
    av_vel = 0.5 * (vel1 + vel2)
    norm1 = norm(segment)
    unit_vector = segment / norm1

    k1 = 0.25 * k # compression stiffness kite segments
    k2 = 0.1 * k  # compression stiffness tether segments
    c1 = 6.0 * c  # damping kite segments
    spring_vel   = rel_vel ⋅ unit_vector
    if (norm1 - l_0) > 0.0
        if i > s.num_E  # kite springs
            s.spring_force .= (k*(l_0 - norm1) - c1 * spring_vel) * unit_vector
        else
            s.spring_force .= (k*(l_0 - norm1) - c * spring_vel) * unit_vector
        end
    elseif i > s.num_E # kite springs
        s.spring_force .= (k1*(l_0 - norm1) - c * spring_vel) * unit_vector
    else
        s.spring_force .= (k2*(l_0 - norm1) - c * spring_vel) * unit_vector
    end

    s.v_apparent .= s.v_wind_tether - av_vel
    area = norm1 * d_tether
    
    v_app_perp = s.v_apparent - s.v_apparent ⋅ unit_vector * unit_vector
    half_drag_force = (0.25 * rho * s.set.cd_tether * norm(v_app_perp) * area) * v_app_perp 
    
    @inbounds s.forces[spring.p1] .+= half_drag_force + s.spring_force
    @inbounds s.forces[spring.p2] .+= half_drag_force - s.spring_force
    if i <= 3 @inbounds s.winch_forces[(i-1)%3+1] .= s.forces[spring.p1] end
    nothing
end

"""
    inner_loop!(s::KPS4_3L, pos, vel, v_wind_gnd, segments, d_tether)

Calculate the forces, acting on all particles.

Output:
- s.forces
- s.v_wind_tether
"""
@inline function inner_loop!(s::KPS4_3L, pos, vel, v_wind_gnd, d_tether)
    for i in eachindex(s.springs)
        p1 = @inbounds s.springs[i].p1  # First point nr.
        p2 = @inbounds s.springs[i].p2  # Second point nr.
        height = 0.5 * (pos[p1][3] + pos[p2][3])
        rho = calc_rho(s.am, height)
        @assert height > 0

        s.v_wind_tether .= calc_wind_factor(s.am, height) * v_wind_gnd
        calc_particle_forces!(s, pos[p1], pos[p2], vel[p1], vel[p2], s.springs[i], d_tether, rho, i)
    end
    nothing
end

"""
    loop!(s::KPS4_3L, pos, vel, posd, veld)

Calculate the vectors s.res1 and calculate s.res2 using loops
that iterate over all tether segments. 
"""
function loop!(s::KPS4_3L, pos, vel, posd, veld)
    L_0      = s.tether_lengths / s.set.segments
    
    mass_per_meter = s.set.rho_tether * π * (s.set.d_tether/2000.0)^2

    for i in 4:s.num_A
        s.res1[i] .= vel[i] .- posd[i]
    end
    # Compute the masses and forces
    mass_tether_particle = mass_per_meter .* s.segment_lengths
    # TODO: check if the next two lines are correct
    damping  = s.set.damping ./ L_0
    c_spring = s.set.c_spring ./ L_0
    for i in 1:s.set.segments*3
        @inbounds s.masses[i] = mass_tether_particle[(i-1)%3+1]
        @inbounds s.springs[i] = SP(s.springs[i].p1, s.springs[i].p2, s.segment_lengths[(i-1)%3+1], c_spring[(i-1)%3+1], damping[(i-1)%3+1])
    end
    inner_loop!(s, pos, vel, s.v_wind_gnd, s.set.d_tether/1000.0)
    for i in s.num_E-2:s.num_E-1
        @inbounds s.forces[i] .+= SVector(0, 0, -G_EARTH) .+ 500.0 .* ((vel[i]-vel[s.num_C]) ⋅ s.e_z) .* s.e_z
        F_xy = SVector(s.forces[i] .- (s.forces[i] ⋅ s.e_z) * s.e_z)
        @inbounds s.forces[i] .-= F_xy
        @inbounds s.forces[i+3] .+= F_xy
        @inbounds s.res2[i] .= (s.veld[i] ⋅ s.e_z) .* s.e_z .- (s.forces[i] ./ s.masses[i])
    end
    for i in 4:s.num_E-3
        @inbounds s.res2[i] .= veld[i] .- (SVector(0, 0, -G_EARTH) .+ s.forces[i] ./ s.masses[i])
    end
    for i in s.num_E:s.num_A
        @inbounds s.res2[i] .= veld[i] .- (SVector(0, 0, -G_EARTH) .+ s.forces[i] ./ s.masses[i])
    end
    nothing
end

"""
    residual!(res, yd, y::MVector{S, SimFloat}, s::KPS4, time) where S

    N-point tether model, four points for the kite on top:
    Inputs:
        State vector y   = pos1,  pos2, ... , posn, vel1,  vel2, . .., veln, connection_length1-2, connection_vel1-2, length1-3, reel_out_speed1-3
        Derivative   yd  = posd1, posd2, ..., posdn, veld1, veld2, ..., veldn, connection_lengthd1-2, connection_veld1-2, lengthd1-3, reel_out_speedd1-3
        - Without points 1 2 and 3, because they are stationary.
        - With left and right tether points replaced by connection lengths, so they are described by only 1 number instead of 3.
    Output:
    Residual     res = (res1, res2)
        res1 = vel1-posd1,  ..., connection_vel1-connection_vel2
        res2 = veld1-acc1, ..., connection_veld1-connection_veld2
    Will be solved so that res --> 0

    Additional parameters:
    s: Struct with work variables, type KPS4
    S: The dimension of the state vector
The number of the point masses of the model N = S/6, the state of each point 
is represented by two 3 element vectors.
"""
function residual!(res, yd, y::Vector{SimFloat}, s::KPS4_3L, time)
    S = length(y)
    y_ =  MVector{S, SimFloat}(y)
    yd_ =  MVector{S, SimFloat}(yd)
    residual!(res, yd_, y_, s, time)
end
function residual!(res, yd, y::MVector{S, SimFloat}, s::KPS4_3L, time) where S
    num_particles = div(S-6-4, 6) # total number of 3-dimensional particles in y, so excluding 3 stationary points and 2 wire points
    for i in 1:s.num_A
        s.forces[i] .= SVector(0.0, 0, 0)
    end
    # extract the data for the winch simulation
    lengths = @view y[end-5:end-3]
    reel_out_speeds = @view y[end-2:end]

    lengthsd = @view yd[end-5:end-3]
    reel_out_speedsd = @view yd[end-2:end]

    # extract the data of the particles
    y_  = @view y[1:end-6]
    yd_ = @view yd[1:end-6]

    # unpack the vector y
    coordinates = reshape(SVector{6*num_particles}(@view y_[1:6*num_particles]), Size(3, num_particles, 2))
    connections = reshape(SVector{4}(@view y_[6*num_particles+1:6*num_particles+4]), Size(2, 2))

    # unpack the vector yd
    coordinatesd = reshape(SVector{6*num_particles}(@view yd_[1:6*num_particles]), Size(3, num_particles, 2))
    connectionsd = reshape(SVector{4}(@view yd_[6*num_particles+1:6*num_particles+4]), Size(2, 2))

    E, C, D = SVector(coordinates[:,num_particles-3,1]), SVector(coordinates[:,num_particles-2,1]), SVector(coordinates[:,num_particles-1,1])
    vC, vD = SVector(coordinates[:,num_particles-2,2]), SVector(coordinates[:,num_particles-1,2])
    Cd, Dd = SVector(coordinatesd[:,num_particles-2,1]), SVector(coordinatesd[:,num_particles-1,1])
    vCd, vDd = SVector(coordinatesd[:,num_particles-2,2]), SVector(coordinatesd[:,num_particles-1,2])

    calc_kite_ref_frame!(s, E, C, D)
    connection_lengths = SVector(connections[:,1])

    # convert y and yd to a nice list of coordinates
    for i in 1:3
        s.pos[i] .= SVector(0.0, 0, 0)
        s.vel[i] .= SVector(0.0, 0, 0)
        s.posd[i] .= SVector(0.0, 0, 0)
        s.veld[i] .= SVector(0.0, 0, 0)
    end
    for i in 4:s.num_E-3
        s.pos[i] .= SVec3(coordinates[:, i-3, 1])
        s.vel[i] .= SVec3(coordinates[:,i-3,2])
        s.posd[i] .= SVec3(coordinatesd[:,i-3,1])
        s.veld[i] .= SVec3(coordinatesd[:,i-3,2])
    end
    s.pos[s.num_E-2] .= SVec3(C .+ s.e_z.*connections[1,1])
    s.vel[s.num_E-2] .= SVec3(vC + s.e_z*connections[1,2])
    s.posd[s.num_E-2] .= SVec3(Cd + s.e_z.*connectionsd[1,1])
    s.veld[s.num_E-2] .= SVec3(vCd + s.e_z*connectionsd[1,2])
    s.pos[s.num_E-1] .= SVec3(D .+ s.e_z.*connections[2,1])
    s.vel[s.num_E-1] .= SVec3(vD + s.e_z*connections[2,2])
    s.posd[s.num_E-1] .= SVec3(Dd + s.e_z.*connectionsd[2,1])
    s.veld[s.num_E-1] .= SVec3(vDd + s.e_z*connectionsd[2,2])
    for i in s.num_E:s.num_A
        s.pos[i] .= (coordinates[:,i-5,1])
        s.vel[i] .= SVec3(coordinates[:,i-5,2])
        s.posd[i] .= SVec3(coordinatesd[:,i-5,1])
        s.veld[i] .= SVec3(coordinatesd[:,i-5,2])
    end
    @assert isfinite(s.pos[4][3])

    # core calculations
    s.tether_lengths .= lengths
    s.steering_pos .= connection_lengths
    s.segment_lengths .= lengths ./ s.set.segments
    calc_aero_forces!(s, s.pos, s.vel)
    loop!(s, s.pos, s.vel, s.posd, s.veld)

    # winch calculations
    res[end-5:end-3] .= lengthsd .- reel_out_speeds
    for i in 1:3
        # @time res[end-3+i] = 1.0 - calc_acceleration(s.motors[i], 1.0, norm(s.forces[(i-1)%3+1]); set_speed=1.0, set_torque=s.set_values[i], use_brake=true)
        if !s.torque_control
            res[end-3+i] = reel_out_speedsd[i] - calc_acceleration(s.motors[i], reel_out_speeds[i], norm(s.forces[(i-1)%3+1]); set_speed=s.set_values[i], set_torque=nothing, use_brake=true)
        else
            res[end-3+i] = reel_out_speedsd[i] - calc_acceleration(s.motors[i], reel_out_speeds[i], norm(s.forces[(i-1)%3+1]); set_speed=nothing, set_torque=s.set_values[i], use_brake=true)
        end
    end

    for i in 4:s.num_E-3
        for k in 1:3
            @inbounds res[3*(i-4)+k] = s.res1[i][k]
            @inbounds res[3*num_particles+2+3*(i-4)+k] = s.res2[i][k]
        end
    end
    for i in s.num_E:s.num_A
        for k in 1:3
            @inbounds res[3*(i-6)+k] = s.res1[i][k]
            @inbounds res[3*num_particles+2+3*(i-6)+k] = s.res2[i][k]
        end
    end

    # add connection residuals
    res[3*num_particles+1] = (s.res1[s.num_E-2]) ⋅ s.e_z - (s.res1[s.num_C] ⋅ s.e_z)
    res[3*num_particles+2] = (s.res1[s.num_E-1]) ⋅ s.e_z - (s.res1[s.num_D] ⋅ s.e_z)
    res[6*num_particles+3] = (s.res2[s.num_E-2]) ⋅ s.e_z - (s.res2[s.num_C] ⋅ s.e_z)
    res[6*num_particles+4] = (s.res2[s.num_E-1]) ⋅ s.e_z - (s.res2[s.num_D] ⋅ s.e_z)

    s.vel_kite .= s.vel[s.num_A]
    s.steering_vel .= ((s.vel[s.num_E-2]-s.vel[s.num_C]) ⋅ s.e_z)
    s.reel_out_speeds .= reel_out_speeds

    @assert isfinite(norm(res))
    s.iter += 1
    return nothing
end


# =================== getter functions ====================================================

"""
    calc_height(s::KPS4_3L)

Determine the height of the topmost kite particle above ground.
"""
function calc_height(s::KPS4_3L)
    pos_kite(s)[3]
end

"""
    pos_kite(s::KPS4_3L)

Return the position of the kite (top particle).
"""
function pos_kite(s::KPS4_3L)
    s.pos[end]
end

"""
    kite_ref_frame(s::KPS4_3L)

Returns a tuple of the x, y, and z vectors of the kite reference frame.
"""
function kite_ref_frame(s::KPS4_3L)
    s.e_x, s.e_y, s.e_z
end

"""
    winch_force(s::KPS4_3L)

Return the absolute value of the force at the winch as calculated during the last timestep. 
"""
function winch_force(s::KPS4_3L) norm.(s.winch_forces) end

# ==================== end of getter functions ================================================

# not implemented
function spring_forces(s::KPS4_3L)
    forces = zeros(SimFloat, s.num_A)
    for i in 1:s.set.segments*3
        forces[i] =  s.springs[i].c_spring * (norm(s.pos[i+3] - s.pos[i]) - s.segment_lengths[(i-1)%3+1]) * s.stiffness_factor
        if forces[i] > 4000.0
            println("Tether raptures for segment $i !")
        end
    end
    for i in 1:KITE_SPRINGS_3L
        p1 = s.springs[i+s.set.segments*3].p1  # First point nr.
        p2 = s.springs[i+s.set.segments*3].p2  # Second point nr.
        pos1, pos2 = s.pos[p1], s.pos[p2]
        spring = s.springs[i+s.set.segments*3]
        l_0 = spring.length # Unstressed lengthc_spring
        k = spring.c_spring * s.stiffness_factor       # Spring constant 
        segment = pos1 - pos2
        norm1 = norm(segment)
        k1 = 0.25 * k # compression stiffness kite segments
        if (norm1 - l_0) > 0.0
            spring_force = k *  (norm1 - l_0) 
        else 
            spring_force = k1 *  (norm1 - l_0)
        end
        forces[i+s.set.segments*3] = spring_force
        if norm(s.spring_force) > 4000.0
            println("Bridle brakes for spring $i !")
        end
    end
    forces
end

"""
    find_steady_state!(s::KPS4_3L; prn=false, delta = 0.0, stiffness_factor=0.035)

Find an initial equilibrium, based on the inital parameters
`l_tether`, elevation and `reel_out_speeds`.

    X00: parameters that change the shape of the kite system. There are s.set.segments*4+5 params in total
        - s.set.segments*2 parameters for middle_tether
        - 5 parameters for bridlepoints
        - s.set.segments*2 parameters for left_tether

"""
function find_steady_state!(s::KPS4_3L; prn=false, delta = 0.0, stiffness_factor=0.035)
    s.stiffness_factor = stiffness_factor
    res = zeros(MVector{6*(s.num_A-5)+4+6, SimFloat})
    iter = 0

    # helper function for the steady state finder
    function test_initial_condition!(F, x::Vector)
        x1 = copy(x)
        y0, yd0 = init(s, x1)
        residual!(res, yd0, y0, s, 0.0)
        
        # middle tether
        for (i, j) in enumerate(range(6, step=3, length=s.set.segments))
            F[i] = s.res2[j][1]
            F[i+s.set.segments] = s.res2[j][3]
        end

        # point A and C
        F[2*s.set.segments+1] = s.res2[s.num_A][1]
        F[2*s.set.segments+2] = s.res2[s.num_A][3]
        F[2*s.set.segments+3 : 2*s.set.segments+5] = s.res2[s.num_C]

        # left tether length
        F[2*s.set.segments+6] = norm(s.res2[s.num_E-2] - s.res2[s.num_C])

        # left tether
        for (i, j) in enumerate(range(4, step=3, length=s.set.segments-1))
            F[2*s.set.segments+6+i] = s.res2[j][1]
            F[3*s.set.segments+5+i] = s.res2[j][2]
            F[4*s.set.segments+4+i] = s.res2[j][3]
        end
        iter += 1
        return nothing
    end
    if prn println("\nStarted function test_nlsolve...") end
    X00 = zeros(SimFloat, 5*s.set.segments+3)
    results = nlsolve(test_initial_condition!, X00, autoscale=true, xtol=2e-7, ftol=2e-7, iterations=s.set.max_iter)
    if prn println("\nresult: $results") end
    if s.mtk
        return init_pos(s, results.zero), nothing
    else
        return init(s, results.zero)
    end
end
