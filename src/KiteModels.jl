#= MIT License

Copyright (c) 2020, 2021 Uwe Fechner

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

This model implements a 3D mass-spring system with reel-out. It uses five tether segments (the number can be
configured in the file data/settings.yaml). The kite is modelled as additional mass at the end of the tether.
The spring constant and the damping decrease with the segment length. The aerodynamic kite forces are
calculated, depending on reel-out speed, depower and steering settings. 

Scientific background: http://arxiv.org/abs/1406.6218 =#

module KiteModels

using Dierckx, StaticArrays, LinearAlgebra, Parameters, NLsolve, DocStringExtensions
using KiteUtils, KitePodSimulator

export KPS3, KVec3, SimFloat, ProfileLaw, EXP, LOG, EXPLOG                                        # constants and types
export calc_rho, calc_wind_factor, calc_drag, calc_set_cl_cd, clear, find_steady_state, residual! # environment and helper functions
export set_v_reel_out, set_depower_steering                                                       # setters
export get_force, get_lod                                                                         # getters

set_zero_subnormals(true)         # required to avoid drastic slow down on Intel CPUs when numbers become very small

# Constants
const G_EARTH = 9.81                # gravitational acceleration
const BRIDLE_DRAG = 1.1             # should probably be removed

# Type definitions
"""
    const SimFloat = Float64

This type is used for all real variables, used in the Simulation. Possible alternatives: Float32, Double64, Dual
Other types than Float64 or Float32 do require support of Julia types by the solver. 
"""
const SimFloat = Float64

"""
   const KVec3    = MVector{3, SimFloat}

Basic 3-dimensional vector, stack allocated, mutable.
"""
const KVec3    = MVector{3, SimFloat}

"""
   const SVec3    = SVector{3, SimFloat}

Basic 3-dimensional vector, stack allocated, immutable.
"""
const SVec3    = SVector{3, SimFloat}  

# the following two definitions speed up the function residual! from 940ns to 540ns
# disadvantage: changing the cl and cd curves requires a restart of the program     
const calc_cl = Spline1D(se().alpha_cl, se().cl_list)
const calc_cd = Spline1D(se().alpha_cd, se().cd_list)  

"""
    abstract type AbstractKiteModel

All kite models must inherit from this type. All methods that are defined on this type must work
with all kite models. All exported methods must work on this type. 
"""
abstract type AbstractKiteModel end

"""
    const AKM = AbstractKiteModel

Short alias for the AbstractKiteModel. 
"""
const AKM = AbstractKiteModel

include("KPS4.jl")

"""
    mutable struct KPS3{S, T, P} <: AbstractKiteModel

State of the kite power system. Parameters:
- S: Scalar type, e.g. SimFloat
  In the documentation mentioned as Any, but when used in this module it is always SimFloat and not Any.
- T: Vector type, e.g. MVector{3, SimFloat}
- P: number of points of the system, segments+1

Normally a user of this package will not have to access any of the members of this type directly,
use the input and output functions instead.

$(TYPEDFIELDS)
"""
@with_kw mutable struct KPS3{S, T, P} <: AbstractKiteModel
    "Reference to the settings struct"
    set::Settings = se()
    "Reference to the KCU struct (Kite Control Unit, type from the module KitePodSimulor"
    kcu::KCU = KCU()
    "Function for calculation the lift coefficent, using a spline based on the provided value pairs."
    calc_cl = Spline1D(se().alpha_cl, se().cl_list)
    "Function for calculation the drag coefficent, using a spline based on the provided value pairs."
    calc_cd = Spline1D(se().alpha_cd, se().cd_list)   
    "wind vector at the height of the kite" 
    v_wind::T =           zeros(S, 3)
    "wind vector at reference height" 
    v_wind_gnd::T =       zeros(S, 3)
    "wind vector used for the calculation of the tether drag"
    v_wind_tether::T =    zeros(S, 3)
    "apparent wind vector at the kite"
    v_apparent::T =       zeros(S, 3)
    v_app_perp::T =       zeros(S, 3)
    drag_force::T =       zeros(S, 3)
    lift_force::T =       zeros(S, 3)
    steering_force::T =   zeros(S, 3)
    last_force::T =       zeros(S, 3)
    spring_force::T =     zeros(S, 3)
    total_forces::T =     zeros(S, 3)
    force::T =            zeros(S, 3)
    unit_vector::T =      zeros(S, 3)
    av_vel::T =           zeros(S, 3)
    kite_y::T =           zeros(S, 3)
    segment::T =          zeros(S, 3)
    last_tether_drag::T = zeros(S, 3)
    acc::T =              zeros(S, 3)     
    vec_z::T =            zeros(S, 3)
    pos_kite::T =         zeros(S, 3)
    v_kite::T =           zeros(S, 3)        
    res1::SVector{P, KVec3} = zeros(SVector{P, KVec3})
    res2::SVector{P, KVec3} = zeros(SVector{P, KVec3})
    pos::SVector{P, KVec3} = zeros(SVector{P, KVec3})
    "area of one tether segment"
    seg_area::S =         zero(S) 
    bridle_area::S =      zero(S)
    "spring constant, depending on the length of the tether segment"
    c_spring::S =         zero(S)
    length::S =           0.0
    "damping factor, depending on the length of the tether segment"
    damping::S =          zero(S)
    area::S =             zero(S)
    last_v_app_norm_tether::S = zero(S)
    "lift coefficient of the kite, depending on the angle of attack"
    param_cl::S =         0.2
    "drag coefficient of the kite, depending on the angle of attack"
    param_cd::S =         1.0
    v_app_norm::S =       zero(S)
    cor_steering::S =     zero(S)
    psi::S =              zero(S)
    "elevation angle in radian; initial value about 70 degrees"
    beta::S =             1.22
    last_alpha::S =        0.1
    alpha_depower::S =     0.0
    "relative start time of the current time interval"
    t_0::S =               0.0
    v_reel_out::S =        0.0
    last_v_reel_out::S =   0.0
    l_tether::S =          0.0
    rho::S =               0.0
    depower::S =           0.0
    steering::S =          0.0
    "initial masses of the point masses"
    initial_masses::MVector{P, SimFloat} = ones(P)
    "current masses, depending on the total tether length"
    masses::MVector{P, SimFloat}         = ones(P)
end

"""
    clear(s::KPS3)

Initialize the kite power model.
"""
function clear(s::KPS3)
    s.t_0 = 0.0                              # relative start time of the current time interval
    s.v_reel_out = 0.0
    s.last_v_reel_out = 0.0
    s.area = s.set.area
    s.v_wind        .= [s.set.v_wind, 0, 0]    # wind vector at the height of the kite
    s.v_wind_gnd    .= [s.set.v_wind, 0, 0]    # wind vector at reference height
    s.v_wind_tether .= [s.set.v_wind, 0, 0]
    s.v_apparent    .= [s.set.v_wind, 0, 0]
    s.l_tether = s.set.l_tether
    s.length = s.l_tether / s.set.segments
    s.pos_kite, s.v_kite = zeros(SimFloat, 3), zeros(SimFloat, 3)
    # density_per_meter = s.set.rho_tether * π * s.set.d_tether^2
    s.initial_masses .= ones(s.set.segments+1) * 0.011 * s.set.l_tether / s.set.segments # Dyneema: 1.1 kg/ 100m
    s.rho = s.set.rho_0
    s.c_spring = s.set.c_spring / s.length
    s.damping  = s.set.damping / s.length
    s.calc_cl = Spline1D(s.set.alpha_cl, s.set.cl_list)
    s.calc_cd = Spline1D(s.set.alpha_cd, s.set.cd_list) 
end

function KPS3(kcu::KCU)
    s = KPS3{SimFloat, KVec3, kcu.set.segments+1}()
    s.set = kcu.set
    s.kcu = kcu
    s.calc_cl = Spline1D(s.set.alpha_cl, s.set.cl_list)
    s.calc_cd = Spline1D(s.set.alpha_cd, s.set.cd_list)       
    clear(s)
    return s
end

"""
    calc_rho(s, height)

Calculate the air densisity as function of height.
"""
function calc_rho(s::AKM, height) s.set.rho_0 * exp(-height / 8550.0) end

"""
    ProfileLaw

Enumeration to describe the wind profile low that is used.
"""
@enum ProfileLaw EXP=1 LOG=2 EXPLOG=3

"""
    calc_wind_factor(s, height, profile_law=s.set.profile_law)

Calculate the relative wind speed at a given height and reference height.
"""
function calc_wind_factor(s, height, profile_law=s.set.profile_law)
    if profile_law == EXP
        return (height / s.set.h_ref)^s.set.alpha
    elseif profile_law == LOG
        return log(height / s.set.z0) / log(s.set.h_ref / s.set.z0)
    else
        K = 1.0
        log1 = log(height / s.set.z0) / log(s.set.h_ref / s.set.z0)
        exp1 = (height / s.set.h_ref)^s.set.alpha
        return log1 +  K * (log1 - exp1)
    end
end

"""
    calc_drag(s::KPS3, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)

Calculate the drag of one tether segment, result stored in parameter last_tether_drag.
Return the norm of the apparent wind velocity.
"""
function calc_drag(s::KPS3, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)
    s.v_apparent .= s.v_wind_tether - v_segment
    v_app_norm = norm(s.v_apparent)
    v_app_perp .= s.v_apparent .- dot(s.v_apparent, unit_vector) .* unit_vector
    last_tether_drag .= -0.5 * s.set.cd_tether * rho * norm(v_app_perp) * area .* v_app_perp
    v_app_norm
end 

#     pos_kite:     position of the kite
#     rho:          air density [kg/m^3]
#     paramCD:      drag coefficient (function of power settings)
#     paramCL:      lift coefficient (function of power settings)
#     rel_steering: value between -1.0 and +1.0
function calc_aero_forces(s::KPS3, pos_kite, v_kite, rho, rel_steering)
    s.v_apparent    .= s.v_wind - v_kite
    s.v_app_norm     = norm(s.v_apparent)
    s.drag_force    .= s.v_apparent ./ s.v_app_norm
    s.kite_y        .= normalize(cross(pos_kite, s.drag_force))
    K                = 0.5 * rho * s.v_app_norm^2 * s.set.area
    s.lift_force    .= K * s.param_cl .* normalize(cross(s.drag_force, s.kite_y))   
    # some additional drag is created while steering
    s.drag_force    .*= K * s.param_cd * BRIDLE_DRAG * (1.0 + 0.6 * abs(rel_steering)) 
    s.cor_steering    = s.set.c2_cor / s.v_app_norm * sin(s.psi) * cos(s.beta) # in paper named i_(s,c), Eq. 30
    s.steering_force .= -K * s.set.rel_side_area/100.0 * s.set.c_s * (rel_steering + s.cor_steering) .* s.kite_y
    s.last_force     .= -(s.lift_force + s.drag_force + s.steering_force) 
    nothing
end

# Calculate the vector res1, that depends on the velocity and the acceleration.
# The drag force of each segment is distributed equaly on both particles.
function calc_res(s::KPS3, pos1, pos2, vel1, vel2, mass, veld, result, i)
    s.segment .= pos1 - pos2
    height = (pos1[3] + pos2[3]) * 0.5
    rho = calc_rho(s, height)               # calculate the air density
    rel_vel = vel1 - vel2                # calculate the relative velocity
    s.av_vel .= 0.5 * (vel1 + vel2)
    norm1 = norm(s.segment)
    s.unit_vector .= normalize(s.segment) # unit vector in the direction of the tether
    # # look at: http://en.wikipedia.org/wiki/Vector_projection
    # # calculate the relative velocity in the direction of the spring (=segment)
    spring_vel = dot(s.unit_vector, rel_vel)

    k2 = 0.05 * s.c_spring             # compression stiffness tether segments
    if norm1 - s.length > 0.0
        s.spring_force .= (s.c_spring * (norm1 - s.length) + s.damping * spring_vel) .* s.unit_vector
    else
        s.spring_force .= k2 * ((norm1 - s.length) + (s.damping * spring_vel)) .* s.unit_vector
    end
    s.seg_area = norm1 * s.set.d_tether/1000.0
    s.last_v_app_norm_tether = calc_drag(s, s.av_vel, s.unit_vector, rho, s.last_tether_drag, s.v_app_perp, s.seg_area)
    
    s.force .= s.spring_force + 0.5 * s.last_tether_drag
    if i == s.set.segments+1
        s.bridle_area =  s.set.l_bridle * s.set.d_line/1000.0
        s.last_v_app_norm_tether = calc_drag(s, s.av_vel, s.unit_vector, rho, s.last_tether_drag, s.v_app_perp, s.bridle_area)
        s.force .+= s.last_tether_drag  
    end
   
    s.total_forces .= s.force + s.last_force
    s.last_force .= 0.5 * s.last_tether_drag - s.spring_force
    s.acc .= s.total_forces ./ mass # create the vector of the spring acceleration
    result .= veld - (SVector(0, 0, -G_EARTH) - s.acc)
    nothing
end

# Calculate the vector res1 using a vector expression, and calculate res2 using a loop
# that iterates over all tether segments. 
function loop(s::KPS3, pos, vel, posd, veld, res1, res2)
    s.masses               .= s.length / (s.set.l_tether / s.set.segments) .* s.initial_masses
    s.masses[s.set.segments+1]   += (s.set.mass + s.set.kcu_mass)
    res1[1] .= pos[1]
    res2[1] .= vel[1]
    for i in 2:s.set.segments+1
        res1[i] .= vel[i] - posd[i]
    end
    for i in s.set.segments+1:-1:2
        calc_res(s, pos[i], pos[i-1], vel[i], vel[i-1], s.masses[i], veld[i],  res2[i], i)
    end
    nothing
end

# Calculate the lift and drag coefficient as a function of the relative depower setting.
function set_cl_cd(s, alpha)   
    angle =  alpha * 180.0 / π
    if angle > 180.0
        angle -= 360.0
    end
    if angle < -180.0
        angle += 360.0
    end
    s.param_cl = calc_cl(angle)
    s.param_cd = calc_cd(angle)
    nothing
end

# Calculate the angle of attack alpha from the apparend wind velocity vector
# v_app and the z unit vector of the kite reference frame.
function calc_alpha(v_app, vec_z)
    π/2.0 - acos(-dot(v_app, vec_z) / norm(v_app))
end


"""
    calc_set_cl_cd(s, vec_c, v_app)

Calculate the lift over drag ratio as a function of the direction vector of the last tether
segment, the current depower setting and the apparent wind speed.
Set the calculated CL and CD values in the struct s. 
"""
function calc_set_cl_cd(s, vec_c, v_app)
    s.vec_z .= normalize(vec_c)
    alpha = calc_alpha(v_app, s.vec_z) - s.alpha_depower
    set_cl_cd(s, alpha)
end

"""
    residual!(res, yd, y::MVector{S, SimFloat}, s::KPS3, time) where S

    N-point tether model, one point kite at the top:
    Inputs:
    State vector y   = pos1, pos2, ..., posn, vel1, vel2, ..., veln
    Derivative   yd  = vel1, vel2, ..., veln, acc1, acc2, ..., accn
    Output:
    Residual     res = res1, res2 = pos1,  ..., vel1, ...

    Additional parameters:
    s: Struct with work variables, type KPS3
    S: The dimension of the state vector
The number of the point masses of the model N = S/6, the state of each point 
is represented by two 3 element vectors.
"""
function residual!(res, yd, y::MVector{S, SimFloat}, s::KPS3, time) where S
    # unpack the vectors y and yd
    part = reshape(SVector{S}(y),  Size(3, div(S,6), 2))
    partd = reshape(SVector{S}(yd),  Size(3, div(S,6), 2))
    pos1, vel1 = part[:,:,1], part[:,:,2]
    pos = SVector{div(S,6)+1}(if i==1 SVector(0.0,0,0) else SVector(pos1[:,i-1]) end for i in 1:div(S,6)+1)
    vel = SVector{div(S,6)+1}(if i==1 SVector(0.0,0,0) else SVector(vel1[:,i-1]) end for i in 1:div(S,6)+1)
    posd1, veld1 = partd[:,:,1], partd[:,:,2]
    posd = SVector{div(S,6)+1}(if i==1 SVector(0.0,0,0) else SVector(posd1[:,i-1]) end for i in 1:div(S,6)+1)
    veld = SVector{div(S,6)+1}(if i==1 SVector(0.0,0,0) else SVector(veld1[:,i-1]) end for i in 1:div(S,6)+1)

    # update parameters
    s.pos_kite .= pos[div(S,6)+1]
    s.v_kite   .= vel[div(S,6)+1]
    delta_t = time - s.t_0
    delta_v = s.v_reel_out - s.last_v_reel_out
    s.length = (s.l_tether + s.last_v_reel_out * delta_t + 0.5 * delta_v * delta_t^2) / div(S,6)
    s.c_spring = s.set.c_spring / s.length
    s.damping  = s.set.damping / s.length

    # call core calculation routines
    vec_c = SVector{3, SimFloat}(pos[s.set.segments] - s.pos_kite)     # convert to SVector to avoid allocations
    v_app = SVector{3, SimFloat}(s.v_wind - s.v_kite)
    calc_set_cl_cd(s, vec_c, v_app)
    calc_aero_forces(s, s.pos_kite, s.v_kite, s.rho, s.steering) # force at the kite
    loop(s, pos, vel, posd, veld, s.res1, s.res2)
  
    # copy and flatten result
    for i in 2:div(S,6)+1
        for j in 1:3
           @inbounds res[3*(i-2)+j] = s.res1[i][j]
           @inbounds res[3*(div(S,6))+3*(i-2)+j] = s.res2[i][j]
        end
    end
    if norm(res) < 10.0
        # println(norm(res))
        for i in 1:length(pos)
            @inbounds s.pos[i] .= pos[i]
        end
    end
    nothing
end


"""
    set_v_reel_out(s::AKM, v_reel_out, t_0, period_time = 1.0 / s.set.sample_freq)

Setter for the reel-out speed. Must be called on every timestep (before each simulation).
It also updates the tether length, therefore it must be called even if v_reelout has
not changed.

- t_0 the start time of the next timestep relative to the start of the simulation [s]
"""
function set_v_reel_out(s::AKM, v_reel_out, t_0, period_time = 1.0 / s.set.sample_freq)
    s.l_tether += 0.5 * (v_reel_out + s.last_v_reel_out) * period_time
    s.last_v_reel_out = s.v_reel_out
    s.v_reel_out = v_reel_out
    s.t_0 = t_0
end


"""
    set_depower_steering(s::KPS3, depower, steering)

Setter for the depower and steering model inputs. 
- valid range for steering: -1.0 .. 1.0.  
- valid range for depower: 0 .. 1.0

This function sets the variables s.depower, s.steering and s.alpha_depower. 

It takes the depower offset c0 and the dependency of the steering sensitivity from
the depower settings into account.
"""
function set_depower_steering(s::KPS3, depower, steering)
    s.depower  = depower
    s.alpha_depower = calc_alpha_depower(s.kcu, depower) * (s.set.alpha_d_max / 31.0)
    s.steering = (steering - s.set.c0) / (1.0 + s.set.k_ds * (s.alpha_depower / deg2rad(s.set.alpha_d_max)))
    nothing
end

function set_beta_psi(s::AKM, beta, psi)
    s.beta = beta
    s.psi  = psi
end

"""
    set_l_tether(s::AKM, l_tether)

Setter for the tether reel-out lenght (at zero force). During real-time simulations
use the function [`set_v_reel_out`](@ref) instead.
"""
function set_l_tether(s::AKM, l_tether) s.l_tether = l_tether end

"""
    get_l_tether(s::AKM)

Getter for the tether reel-out lenght (at zero force).
"""
function get_l_tether(s::AKM) s.l_tether end

"""
    get_force(s::AKM)

Return the absolute value of the force at the winch as calculated during the last timestep. 
"""
function get_force(s::AKM) norm(s.last_force) end


"""
    get_spring_forces(s::AKM, pos)

Returns an array of the scalar spring forces of all tether segements.

Input: The vector pos of the positions of the point masses that belong to the tether.    
"""
function get_spring_forces(s::AKM, pos)
    forces = zeros(SimFloat, s.set.segments)
    for i in 1:s.set.segments
        forces[i] =  s.c_spring * (norm(pos[i+1] - pos[i]) - s.length)
    end
    forces
end

"""
    get_lift_drag(s::AKM)

Returns a tuple of the scalar lift and drag forces. 

**Example:**  

    lift, drag = get_lift_drag(kps)
"""
function get_lift_drag(s::AKM) return (norm(s.lift_force), norm(s.drag_force)) end

"""
    get_lod(s::AKM)

Returns the lift-over-drag ratio.
"""
function get_lod(s::AKM)
    lift, drag = get_lift_drag(s)
    return lift / drag
end

# Return the vector of the wind velocity at the height of the kite.
function get_v_wind(s::AKM) s.v_wind end

# Set the vector of the wind-velocity at the height of the kite. As parameter the height,
# the ground wind speed and the wind direction are needed.
# Must be called every 50 ms.
function set_v_wind_ground(s::AKM, height, v_wind_gnd=s.set.v_wind, wind_dir=0.0)
    if height < 6.0
        height = 6.0
    end
    s.v_wind .= v_wind_gnd * calc_wind_factor(s, height) .* [cos(wind_dir), sin(wind_dir), 0]
    s.v_wind_gnd .= [v_wind_gnd * cos(wind_dir), v_wind_gnd * sin(wind_dir), 0.0]
    s.v_wind_tether .= v_wind_gnd * calc_wind_factor(s, height / 2.0) .* [cos(wind_dir), sin(wind_dir), 0]
    s.rho = calc_rho(s, height)
    nothing
end

function tether_length(s::AKM, pos)
    length = 0.0
    for i in 1:s.set.segments
        length += norm(pos[i+1] - pos[i])
    end
    return length
end

function calc_pre_tension(s::AKM)
    forces = get_spring_forces(s, s.pos)
    av_force = 0.0
    for i in 1:s.set.segments
        av_force += forces[i]
    end
    av_force /= s.set.segments
    res = av_force/s.set.c_spring
    if res < 0.0 res = 0.0 end
    if isnan(res) res = 0.0 end
    return res + 1.0
end

# Calculate the initial conditions y0, yd0 and sw0. Tether with the given elevation angle,
# particle zero fixed at origin. """
function init(s, X; output=false)
    pos = zeros(SVector{s.set.segments+1, KVec3})
    vel = zeros(SVector{s.set.segments+1, KVec3})
    acc = zeros(SVector{s.set.segments+1, KVec3})
    state_y0 = zeros(SVector{2*s.set.segments, KVec3})
    yd0 = zeros(SVector{2*s.set.segments, KVec3})

    DELTA = 1e-6
    set_cl_cd(s, 10.0/180.0 * π)

    for i in 0:s.set.segments
        radius =  -i * s.set.l_tether / s.set.segments
        elevation = s.set.elevation
        sin_el, cos_el = sin(elevation / 180.0 * π), cos(elevation / 180.0 * π)
        radius1 = radius
        if i==0
            pos[i+1] .= SVec3(0.0, DELTA, 0.0)
        else
            pos[i+1] .= SVec3(-cos_el * radius1+X[i], DELTA, -sin_el * radius1+X[s.set.segments+i])
        end
        vel[i+1] .= SVec3(DELTA, DELTA, DELTA)
        acc[i+1] .= SVec3(DELTA, DELTA, DELTA)
    end
    for i in 1:length(pos)
        s.pos[i] .= pos[i]
    end

    if output
        forces = get_spring_forces(s, pos)
        println("Winch force: $(norm(forces[1])) N"); 
    end
    
    for i in 2:s.set.segments+1
        state_y0[i-1] .= pos[i]  # Initial state vector
        yd0[i-1]      .= vel[i]  # Initial state vector derivative
    end

    for i in 2:s.set.segments+1
        state_y0[s.set.segments+i-1] .= vel[i]  # Initial state vector
        yd0[s.set.segments+i-1]      .= acc[i]  # Initial state vector derivative
    end
    set_v_wind_ground(s, pos[s.set.segments+1][3])
    set_l_tether(s, s.set.l_tether)
    set_v_reel_out(s, s.set.v_reel_out, 0.0)
    if output
        print("y0: ")
        display(state_y0)
        print("yd0: ")
        display(yd0)
    end
    return reduce(vcat, state_y0), reduce(vcat, yd0)
end

"""
    find_steady_state(s::KPS3, prn=false)

Find an initial equilibrium, based on the inital parameters
l_tether, elevation and v_reel_out.
"""
function find_steady_state(s::KPS3, prn=false)
    res = zeros(MVector{6*s.set.segments, SimFloat})
    state = s

    # helper function for the steady state finder
    function test_initial_condition!(F, x::Vector)
        y0, yd0 = init(state, x)
        residual!(res, yd0, y0, state, 0.0)
        for i in 1:s.set.segments
            F[i] = res[1 + 3*(i-1) + 3*s.set.segments]
            F[i+s.set.segments] = res[3 + 3*(i-1) + 3*s.set.segments]
        end
        return nothing 
    end
    if prn println("\nStarted function test_nlsolve...") end
    results = nlsolve(test_initial_condition!, zeros(SimFloat, 2*s.set.segments))
    if prn println("\nresult: $results") end
    res = init(s, results.zero; output=false)
    res
end

precompile(find_steady_state, (KPS3{SimFloat, KVec3, 7},))   

end