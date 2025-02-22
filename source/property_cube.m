function [x,y,z,cube] = property_cube(entity,fname,property,address,resolution,pH,I)
%
% PROPERTY_CUBE Makes cube maps of esidue properties for an ensemble 
%
%   [x,y,z,cube] = property_cube(entity,fname,property)
%   Computes cube map and stores it in MRC or .mat cube file fname
%
%   [x,y,z,cube] = property_cube(entity,fname,property,address)
%   Restricts computation to the part selected by address
%
%   [x,y,z,cube] = property_cube(entity,fname,property,address,resolution)
%   Defines a grid resolution in Angstrom
%
%   [x,y,z,cube] = property_cube(entity,fname,property,address,resolution,pH)
%   Defines the pH value (defaults to 7)
%
% INPUT
% entity       entity in an MMMx format, must be provided
% fname        file name for output, extension .mrc is
%              appended, if none is present
% property     can be any of
%              'electrostatic'  simplified Coulomb map
%              'cation-pi'  map of cation-pi interaction
%              'hydrophobic'  map of hydrophobicity/hydrophilicity
% address      MMMx address, defaults to 'everything'
% resolution   (optional) grid resolution in Angstrom
% pH           pH value, defaults to 7
% I            ionic strength, defaults to 150 mmol/L
%
% OUTPUT
% x,y,z        cube axes (Angstrom)
% cube         density cube
%
% electrostatic potential is modelled by Coulomb decay of fixed point
% charges, use only for visualization, not for thermodynamics
%
% cation-pi weightings from:
% J.P. Gallivan, D.A. Dougherty, PNAS 96, 9459-9464 (1999)
% DOI: 10.1073/pnas.96.17.9459
%
% hydrophobicity corresponds to the Wimley-White scale:
% W.C. Wimley, S.H. White, Nat. Struct. Mol. Biol. 3, 842-848 (1996)
% DOI: 10.1038/nsb1096-842
%
% exponential decay of the hydrophobic interaction with a decay length of
% 10 Å follows:
% J. Israelachvili, R. Psshley, Nature, 300, 341-342 (1982)
%
% the cube data can be used for coloring of a density cube generated by
% mk_density

% This file is a part of MMMx. License is MIT (see LICENSE.md). 
% Copyright(c) 2023: Gunnar Jeschke

decay_length = 10; % decay length for hydrophobic interaction, Israelachvili/Pashley value

% default selection is everything (all chains)
if ~exist('address','var') || isempty(address)
    address = '(*)';
end

% default pH is 7
if ~exist('pH','var') || isempty(pH)
    pH = 7;
end

% append extension .mrc to file name, if there is none
if ~contains(fname,'.')
    fname = [fname '.mrc'];
end

if ~exist('I','var') || isempty(I)
    I = 0.150;
end
lambda_D = debye_length(I);

slater_generic = 0.75; % generic Slater radius for heavy atoms, 75 pm to include hydrogen

rez = slater_generic/2; % default resolution, very high
if exist('resolution','var') && ~isempty(resolution)
    rez = resolution;
end

pop = entity.populations;
C = length(entity.populations); % number of conformers
min_xyz = [1e6,1e6,1e6];
max_xyz = [-1e6,-1e6,-1e6];
for c = 1:C
    coor = get_coor(entity,sprintf('{%i}%s',c,address),true);
    max_xyz0 = max(coor) + 3*slater_generic;
    min_xyz0 = min(coor) - 3*slater_generic;
    for k = 1:3
        if max_xyz(k) < max_xyz0(k)
            max_xyz(k) = max_xyz0(k);
        end
        if min_xyz(k) > min_xyz0(k)
            min_xyz(k) = min_xyz0(k);
        end
    end
end
nx = round((max_xyz(1) - min_xyz(1))/rez);
ny = round((max_xyz(2) - min_xyz(2))/rez);
nz = round((max_xyz(3) - min_xyz(3))/rez);
cube = zeros(nx,ny,nz);
x = linspace(min_xyz(1), max_xyz(1), nx);
y = linspace(min_xyz(2) , max_xyz(2), ny);
z = linspace(min_xyz(3), max_xyz(3), nz);

chains = fieldnames(entity);
for kc = 1:length(chains)
    chain = chains{kc};
    if isstrprop(chain(1),'upper') % chain fields start with a capital
        residues = fieldnames(entity.(chain));
        for kr = 1:length(residues) % expand over all residues
            residue = residues{kr};
            if strcmp(residue(1),'R') % these are residue fields
                resname = entity.(chain).(residue).name;
                switch property
                    case 'electrostatic'
                        switch resname
                            case 'ASP'
                                q = get_charge(3.90,pH) - 1;
                                indices = zeros(2,C);
                                indices(1,:) = entity.(chain).(residue).OD1.tab_indices;
                                indices(2,:) = entity.(chain).(residue).OD2.tab_indices;
                            case 'GLU'
                                q = get_charge(4.07,pH) - 1;
                                indices = zeros(2,C);
                                indices(1,:) = entity.(chain).(residue).OE1.tab_indices;
                                indices(2,:) = entity.(chain).(residue).OE2.tab_indices;
                            case 'SEP'
                                q = -2;
                                indices = zeros(3,C);
                                indices(1,:) = entity.(chain).(residue).OPA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).OPB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).OPC.tab_indices;
                            case 'SPO'
                                q = -2;
                                indices = zeros(3,C);
                                indices(1,:) = entity.(chain).(residue).OE1.tab_indices;
                                indices(2,:) = entity.(chain).(residue).OE2.tab_indices;
                                indices(3,:) = entity.(chain).(residue).OE3.tab_indices;
                            case 'THP'
                                q = -2;
                                indices = zeros(3,C);
                                indices(1,:) = entity.(chain).(residue).OPA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).OPB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).OPC.tab_indices;
                            case 'TPO'
                                q = -2;
                                indices = zeros(3,C);
                                indices(1,:) = entity.(chain).(residue).OE1.tab_indices;
                                indices(2,:) = entity.(chain).(residue).OE2.tab_indices;
                                indices(3,:) = entity.(chain).(residue).OE3.tab_indices;
                            case 'HIS'
                                q = get_charge(6.04,pH);
                                indices = zeros(2,C);
                                indices(1,:) = entity.(chain).(residue).ND1.tab_indices;
                                indices(2,:) = entity.(chain).(residue).NE2.tab_indices;
                            case 'LYS'
                                q = get_charge(10.54,pH);
                                indices = entity.(chain).(residue).NZ.tab_indices;
                            case 'ARG'
                                q = get_charge(12.48,pH);
                                indices = entity.(chain).(residue).CZ.tab_indices;
                            otherwise
                                q = [];
                                indices = [];
                        end
                    case 'cation-pi'
                        switch resname
                            case 'LYS'
                                q = 0.2912*get_charge(10.54,pH)/0.7088;
                                indices = entity.(chain).(residue).NZ.tab_indices;
                            case 'ARG'
                                q = 0.7088*get_charge(12.48,pH)/0.7088;
                                indices = entity.(chain).(residue).CZ.tab_indices;
                            case 'PHE'
                                q = -0.1981/0.5185;
                                indices = zeros(6,C);
                                indices(1,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CD1.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CD2.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CE1.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CE2.tab_indices;
                                indices(6,:) = entity.(chain).(residue).CZ.tab_indices;
                            case 'TYR'
                                q = -0.2834/0.5185;
                                indices = zeros(6,C);
                                indices(1,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CD1.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CD2.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CE1.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CE2.tab_indices;
                                indices(6,:) = entity.(chain).(residue).CZ.tab_indices;
                            case 'TRP'
                                q = -0.5185/0.5185;
                                indices = zeros(6,C);
                                indices(1,:) = entity.(chain).(residue).CD2.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CE2.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CE3.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CZ2.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CZ3.tab_indices;
                                indices(6,:) = entity.(chain).(residue).CH2.tab_indices;
                            otherwise
                                q = [];
                                indices = [];
                        end
                    case 'hydrophobic'
                        switch resname
                            case 'ILE'
                                q = -0.81;
                                indices = zeros(5,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG1.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CG2.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CD1.tab_indices;
                            case 'LEU'
                                q = -0.69;
                                indices = zeros(5,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CD1.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CD2.tab_indices;
                            case 'PHE'
                                q = -0.58;
                                indices = zeros(8,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CZ.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CD1.tab_indices;
                                indices(6,:) = entity.(chain).(residue).CD2.tab_indices;
                                indices(7,:) = entity.(chain).(residue).CE1.tab_indices;
                                indices(8,:) = entity.(chain).(residue).CE2.tab_indices;
                            case 'VAL'
                                q = -0.53;
                                indices = zeros(4,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG1.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CG2.tab_indices;
                            case 'MET'
                                q = -0.44;
                                indices = zeros(5,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).SD.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CE.tab_indices;
                            case 'PRO'
                                q = -0.31;
                                indices = zeros(4,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CD.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CG.tab_indices;
                            case 'TRP'
                                q = -0.24;
                                indices = zeros(11,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CD1.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CD2.tab_indices;
                                indices(6,:) = entity.(chain).(residue).NE1.tab_indices;
                                indices(7,:) = entity.(chain).(residue).CE2.tab_indices;
                                indices(8,:) = entity.(chain).(residue).CE3.tab_indices;
                                indices(9,:) = entity.(chain).(residue).CZ2.tab_indices;
                                indices(10,:) = entity.(chain).(residue).CZ3.tab_indices;
                                indices(11,:) = entity.(chain).(residue).CH2.tab_indices;
                            case 'HIS'
                                charge = get_charge(6.04,pH);
                                q = 1.37*charge - 0.06*(1-charge);
                                indices = zeros(7,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).ND1.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CD2.tab_indices;
                                indices(6,:) = entity.(chain).(residue).CE1.tab_indices;
                                indices(7,:) = entity.(chain).(residue).NE2.tab_indices;
                            case 'THR'
                                q = 0.11;
                                indices = zeros(4,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).OG1.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CG2.tab_indices;
                            case 'GLU'
                                charge = get_charge(4.07,pH);
                                q = 0.19*(1-charge) + 0.12*charge;
                                indices = zeros(6,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CD.tab_indices;
                                indices(5,:) = entity.(chain).(residue).OE1.tab_indices;
                                indices(6,:) = entity.(chain).(residue).OE2.tab_indices;
                            case 'GLN'
                                q = 0.19;
                                indices = zeros(6,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CD.tab_indices;
                                indices(5,:) = entity.(chain).(residue).OE1.tab_indices;
                                indices(6,:) = entity.(chain).(residue).NE2.tab_indices;
                            case 'CYS'
                                q = 0.22;
                                indices = zeros(3,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).SG.tab_indices;
                            case 'TYR'
                                q = 0.23;
                                indices = zeros(9,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CZ.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CD1.tab_indices;
                                indices(6,:) = entity.(chain).(residue).CD2.tab_indices;
                                indices(7,:) = entity.(chain).(residue).CE1.tab_indices;
                                indices(8,:) = entity.(chain).(residue).CE2.tab_indices;
                                indices(9,:) = entity.(chain).(residue).OH.tab_indices;
                            case 'ALA'
                                q = 0.33;
                                indices = zeros(2,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                            case 'SER'
                                q = 0.33;
                                indices = zeros(3,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).OG.tab_indices;
                            case 'ASN'
                                q = 0.43;
                                indices = zeros(5,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).OD1.tab_indices;
                                indices(5,:) = entity.(chain).(residue).ND2.tab_indices;
                            case 'ASP'
                                charge = get_charge(3.90,pH);
                                q = 2.41*(1-charge) + 0.50*charge;
                                indices = zeros(5,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).OD1.tab_indices;
                                indices(5,:) = entity.(chain).(residue).OD2.tab_indices;
                            case 'ARG'
                                q = 1.00;
                                indices = zeros(8,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CZ.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CD.tab_indices;
                                indices(6,:) = entity.(chain).(residue).NE.tab_indices;
                                indices(7,:) = entity.(chain).(residue).NH1.tab_indices;
                                indices(8,:) = entity.(chain).(residue).NH2.tab_indices;
                            case 'GLY'
                                q = 1.14;
                                indices = entity.(chain).(residue).CA.tab_indices;
                            case 'LYS'
                                q = 1.81;
                                indices = zeros(6,C);
                                indices(1,:) = entity.(chain).(residue).CA.tab_indices;
                                indices(2,:) = entity.(chain).(residue).CB.tab_indices;
                                indices(3,:) = entity.(chain).(residue).CG.tab_indices;
                                indices(4,:) = entity.(chain).(residue).CD.tab_indices;
                                indices(5,:) = entity.(chain).(residue).CE.tab_indices;
                                indices(6,:) = entity.(chain).(residue).NZ.tab_indices;
                            otherwise
                                q = [];
                                indices = [];
                       end
                end % switch interaction type, setting up parameters and atom indices
                if ~isempty(q) && ~isempty(indices)
                    for c = 1:C % loop over conformers
                        cindices = indices(:,c); % atom indices for this residue in this conformer
                        coor = entity.xyz(cindices,:); % atom coordinates for this residue in this conformer
                        coor = mean(coor,1); % mean coordinate
                        % make cube with distances to the mean coordinate for
                        % this residue in thsi conformer
                        dx = (x-coor(1)).^2;
                        dy = (y-coor(2)).^2;
                        dz = (z-coor(3)).^2;
                        switch property
                            case 'electrostatic' % exponential scaling, Debye length
                                r = sqrt(repmat(dx',1,ny,nz) + repmat(dy,nx,1,nz) + permute(repmat(dz,nx,1,ny),[1,3,2]));
                                cube = cube + pop(c)*q*exp(-r/lambda_D);
                            case 'cation-pi' % 1/r^2 behavior
                                r2 = repmat(dx',1,ny,nz) + repmat(dy,nx,1,nz) + permute(repmat(dz,nx,1,ny),[1,3,2]);
                                cube = cube + pop(c)*q*1./r2;
                            case 'hydrophobic' % exponential scaling with distance
                                r = sqrt(repmat(dx',1,ny,nz) + repmat(dy,nx,1,nz) + permute(repmat(dz,nx,1,ny),[1,3,2]));
                                cube = cube + pop(c)*q*exp(-r/decay_length);
                        end
                    end
                end
            end % is a residue            
        end % residue fields loop
    end % is a chain
end

[~,~,ext] = fileparts(fname);
switch ext
    case '.mrc'
        writeMRC(cube,rez,fname,[nx,ny,nz],[x(1),y(1),z(1)]);
    case '.mat'
        save(fname,'cube','x','y','z');
end

function charge = get_charge(pKa,pH)

charge = exp(-log(10)*(pH-pKa))/(1+exp(-log(10)*(pH-pKa)));