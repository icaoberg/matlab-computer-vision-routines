%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% advancePhiTVDRK3_Stage3 advances the level set function through the second
% stage of a third-order TVD Runge-Kutta step.
%
% Usage: phi_next = advancePhiTVDRK3_Stage3(phi_stage2, phi_cur, ...
%                                           velocity, ...
%                                           ghostcell_width, ...
%                                           dX, dt, ...
%                                           cfl_number, ...
%                                           spatial_derivative_order)
%
% Arguments:
%   phi_stage2:                phi_approx(t_cur+0.5*dt)
%   phi_cur:                   phi(t_cur)
%   velocity:                  velocity field at t = t_cur
%   ghostcell_width:           number of ghostcells for phi at boundary 
%                                of computational domain
%   dX:                        array containing the grid spacing
%                                in coordinate directions
%   dt:                        step size
%   cfl_number:                CFL number
%                                (default = 0.5)
%   spatial_derivative_order:  order of discretization for spatial derivative 
%                                (default = 5)
%
% Return value:
%   phi_next:                  phi(t_cur + dt)
%
% NOTES:
% - The velocity _must_ be passed in as a cell array of numerical arrays
%   containing the components of the velocity field.  When advancing the 
%   level set equation using an external (vector) velocity field, each 
%   cell represents one component of the velocity field (velocity{1} holds 
%   the velocity in x-direction, velocity{2} holds the velocity in the 
%   y-direction, etc.).  When advancing the level set equation using the
%   velocity in the normal direction, velocity{1} should hold the value
%   of the normal velocity.
%
% - When vector velocity data is supplied, the data arrays for the 
%   components of the velocity are assumed to be the same.
%
% - When dX is a scalar, it is assumed that the grid spacing in each
%   coordinate direction is the same.  Otherwise, dX is treated as
%   a vector with dX(1) = the grid spacing in the x-direction, 
%   dX(2) = the grid spacing in the y-direction, etc.
%
% - The phi_cur data array _must_ have larger dimensions than the 
%   velocity data array, and the velocity data array _must_ have 
%   larger dimensions than the the phi_cur data array with ghostcells
%   removed.
%
% - All data arrays are assumed to be in the order generated by the 
%   MATLAB meshgrid() function.  That is, for 2D arrays, data corresponding 
%   to the point (x_i,y_j) is stored at index (j,i); for 3D arrays, data
%   corresponding to the point (x_i,y_j,z_k) is stored at index (j,i,k).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyrights: (c) 2005 The Trustees of Princeton University and Board of
%                 Regents of the University of Texas.  All rights reserved.
%             (c) 2009 Kevin T. Chu.  All rights reserved.
% Revision:   $Revision: 149 $
% Modified:   $Date: 2009-01-18 00:31:09 -0800 (Sun, 18 Jan 2009) $
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function phi_next = advancePhiTVDRK3_Stage3(phi_stage2, phi_cur, ...
                                            velocity, ...
                                            ghostcell_width, ...
                                            dX, dt, ...
                                            cfl_number, ...
                                            spatial_derivative_order)

% parameter checks
if (nargin < 5)
  error('MATLAB:missingArgs','advancePhiTVDRK3_Stage3:missing arguments');
end

if (nargin < 6)
  cfl_number = 0.5;
else 
  if (cfl_number <= 0)
    error('advancePhiTVDRK3_Stage3:CFL number must be positive');
  end
end

if (nargin < 7)
  spatial_derivative_order = 5;
else 
  if ( (spatial_derivative_order ~= 1) & (spatial_derivative_order ~= 2) ...
     & (spatial_derivative_order ~= 3) & (spatial_derivative_order ~= 5) )

    error('advancePhiTVDRK3_Stage3:Invalid spatial derivative order...only 1, 2, 3, and 5 are supported');
  end
end

% determine dimensionality of problem
num_dims = ndims(phi_cur);
if (num_dims < 1 | num_dims > 3)
  error('advancePhiTVDRK3_Stage3:Invalid dimension...only 1D, 2D, and 3D problems supported');
end

% check that the phi_cur data array is larger than the velocity data array
if ( ~isempty(find(size(phi_cur)<size(velocity{1}))) )
  error('advancePhiTVDRK3_Stage3:velocity data array is smaller than phi_cur data array in at least one dimension.');
end

% compute dX 
if (isscalar(dX))
  dX = dX*ones(num_dims,1);
end

% compute RHS of level set evolution equation
lse_rhs = computeLevelSetEvolutionEqnRHS(phi_stage2, velocity, ...
                                         ghostcell_width, ...
                                         dX, spatial_derivative_order);

% take time step
phi_next = 1/3*phi_cur + 2/3*(phi_stage2 + dt*lse_rhs);