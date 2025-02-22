.. _prepare:

Prepare
==========================

This module helps in preparing input PDB files for other MMMx modules. It can cut and merge existing structures, 
reorient structures based on symmetry or on constructing a coarse-grained lipid bilayer model (requires `MSMS <http://mgl.scripps.edu/people/sanner/html/msms_home.html>`_),
add, repair or modify sidechains (requires `SCWRL4 <http://dunbrack.fccc.edu/SCWRL3.php/>`_), superimpose structures (may require `MUSCLE <http://www.drive5.com/muscle/downloads.htm>`_ if sequence-based),
amd renumber residues. Several processing steps can be performed without saving intermediate results. 

Features are demonstrated in examples ``demo_Prepare.mcx`` and ``demo_RBreference.mcx``. 
The latter example is a two-module pipeline that uses module ``Prepare`` before module :ref:`ExperimentDesign <experiment_design>`. 

The keywords are grouped into input/output (``getpdb``, ``getcyana``, ``save``), 
coordinate transformations (``center``, ``symmetry``, ``bilayer``), 
sidegroup changes (``mutate``, ``repair``, ``repack``, ``deselenate``)
and structure editing (``renumber``, ``chains``, ``replace``, ``remove``, ``merge``).

The following keywords are supported:

``bilayer``
---------------------------------

Computes a coarse-grained bilayer model and transforms coordinates into the bilayer frame. 

.. code-block:: matlab

    bilayer mode orientation identifier 

Arguments
    *   ``mode`` - can be `bundle` for `\alpha`-helical bundles or `barrel` for `\beta`-barrels
    *   ``orientation`` - can be `oriented` if the protein is already properly oriented or `none` if it is not
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   the algorithm minimizes free energy of bilayer insertion	    
    *   the :ref:`third_party` `MSMS <http://mgl.scripps.edu/people/sanner/html/msms_home.html>`_ is required   
    *   the bilayer normal is the new `z` axis	    
    *   if the protein can be oriemted by symmetry, better use ``symmetry`` first and orientation mode ``oriented``	    
    *   the result is not automatically saved, use ``save`` if necessary
	
``center``
---------------------------------

Center the coordinates at the mean coordinate of all atoms 

.. code-block:: matlab

    center identifier

Arguments
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   the result is not automatically saved, use ``save`` if necessary

``chains``
---------------------------------

Restricts an entity to a subset of chains

.. code-block:: matlab

    chains address identifier

Arguments
    *   ``address`` - MMMx chain address, such as ``(A)`` or ``(A,C,E)``
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   the entity with the given identifier is changed, but not automatically saved
    *   use the ``save`` command, if necessary
	
``deselenate``
---------------------------------

Replaces selenocysteine and selenomethionine by their native counterparts cysteine and methionine. 

.. code-block:: matlab

    deselenate identifier

Arguments
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   this function does not require third-party software
    *   seleno amino acids are sometimes used for easier phasing of x-ray diffraction data
	
``getAlphaFold``
---------------------------------

Input of an AlphaFold prediction. 

.. code-block:: matlab

    getAlphaFold UniProtID identifier

Arguments
    *   ``UniProtID`` - UniProt identifier of the AlphaFold prediction
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   note that not for all sequences in UniProt, AlphaFold predictions exist in the database
	
``getcyana``
---------------------------------

Input of a raw ensemble (uniform populations) by reading a single PDB file generated by CYANA. 

.. code-block:: matlab

    getcyana file identifier [maxchains]

Arguments
    *   ``file`` - file name
    *   ``identifier`` - module-internal entity identifier
    *   ``maxchains`` - reading is stopped after the specified number of chains, optional, defaults to all chains
Remarks
    *   information on pseudo-residues is removed
    *   standard PDB residue names are set for nucleic acids
    *   parameter ``maxchains`` allows for skipping pseudo-chains that simulate only labels
    *   residue types CYSS and CYSM are converted to CYS, label atoms in CYSM are skipped

``getens``
---------------------------------

Input of an ensemble by reading an MMMx ensemble list (.ens) 

.. code-block:: matlab

    getens file identifier

Arguments
    *   ``file`` - file name
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   all PDB files of conformers contained in the ensemble list must be on the Matlab path
    *   populations (weights) of conformers are read

``getpdb``
---------------------------------

Input of a raw ensemble (uniform populations) by reading a single PDB file. 

.. code-block:: matlab

    getpdb file identifier

Arguments
    *   ``file`` - file name
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   the PDB file can contain several models (conformers) or a single one
    *   for MMMx ensemble PDB files with population information in ``REMARK 400``, such information is read
	
``merge``
---------------------------------

Merges residue ranges of chains to a new entity. 
The parts can stem from different entitities, thus creating a chimera. 
This is a block key, with each line corresponding to one part. 

.. code-block:: matlab

    merge identifier
      'ID_1 address_1'
	  []
      'ID_n address_n'
    .merge

Arguments
    *   ``identifier`` - module-internal identifier of the newly created entity
    *   ``ID_1`` identifier of the entity from which the first part is taken
    *   ``address_1`` address of the residues from which the first part is taken, e.g. ``{11}(A)58-146`` for residues 58-146 of chain A in conformer 11
    *   ``ID_n`` identifier of the entity from which the last part is taken
    *   ``address_n`` address of the residues from which the last part is taken
Remarks
    *   do *not* use an existing entity identifier
    *   the entity with the given identifier is created, but not automatically saved
    *   use the ``save`` command, if necessary

``mutate``
---------------------------------

Mutates residues. This is a block key with each line corresponding to one residue to be mutated. 

.. code-block:: matlab

    mutate identifier
       'address_1' 'new_residue_1'
       []
       'address_n' 'new_residue_n'
    .mutate

Arguments
    *   ``identifier`` - module-internal entity identifier
    *   ``address_1`` residue address of first residue to be mutated, see :ref:`MMMx_addresses`
    *   ``new_residue_1`` three-letter or single-letter code for new sidechain of first residue
    *   ``address_n`` residue address of last residue to be mutated
    *   ``new_residue_n`` three-letter or single-letter code for new sidechain of last residue
Remarks
    *   :ref:`third_party` `SCWRL4 <http://dunbrack.fccc.edu/SCWRL3.php/>`_ is required
    *   only amino acids, not nucleotides, can be mutated in this version of MMMx

``oligomer``
---------------------------------

Build an oligomer from an oriented peptide chain ensemble

.. code-block:: matlab

    oligomer input N output address

Arguments
    *   ``input`` - module-internal entity identifier for input entity
    *   ``N`` - optional multiplicity, defaults to N = 2 (dimer)
    *   ``output`` - basis name for output files, the filenames are `output`-m-%i.pdb, where %i stands for the conformer number
    *   ``address`` - optional address for chain and residue range, such as ``(A)128-611``, chain defaults to the first chain, and range to all residues	
Remarks
    *   the input entity must be oriented, with the C_N axis of the oligomer being the z axis
    *   from an input entity with C conformers, all C^N possible conformer combinations are generated
    *   an ensemble list `output`.ens with uniform populations (1/C^N) is written as well
	
``remove``
---------------------------------

Remove a residue

.. code-block:: matlab

    remove address idenfifier

Arguments
    *   ``address`` - residue address, such as ``(A)238``
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   the entity with the given identifier is changed, but not automatically saved
    *   use the ``save`` command, if necessary
    *   use the ``merge`` command, if you wish to remove ranges of residues
	
``renumber``
---------------------------------

Renumbers residues in one chain of an entity. 

.. code-block:: matlab

    renumber address shift identifier

Arguments
    *   ``address`` - a chain address, such as ``(A)``
    *   ``shift`` - offset to current residue numbers, can be negative or positive integer
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   use several ``renumber`` lines, if you want to renumber more than one chain 

``repack``
---------------------------------

Repacks all amino acid sidechains in an entity. 

.. code-block:: matlab

    repack identifier

Arguments
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   :ref:`third_party` `SCWRL4 <http://dunbrack.fccc.edu/SCWRL3.php/>`_ is required

``repair``
---------------------------------

Repairs all incompletely defined amino acid sidechains in an entity. 

.. code-block:: matlab

    repair identifier

Arguments
    *   ``identifier`` - module-internal entity identifier
Remarks
    *   :ref:`third_party` `SCWRL4 <http://dunbrack.fccc.edu/SCWRL3.php/>`_ is required

``replace``
---------------------------------

Replaces a chain in one entity with a chain from another entity

.. code-block:: matlab

    replace id_1.chain_1 id_2.chain_2

Arguments
    *   ``id_1.chain_1`` - identifier of target chsin, such as ``BtuCDF.(F)`` for chain ``F`` in entity ``BtuCDF`` to be replaced
    *   ``id_2.chain_2`` - identifier of template chsin, such as ``BtuF_CBI.(A)`` for using ``A`` in entity ``BtuF_CDI`` as a replacement
Remarks
    *   the entity with the given identifier is changed, but not automatically saved
    *   use the ``save`` command, if necessary
			
``save``
---------------------------------

Save a (modified) entity to a PDB file. 

.. code-block:: matlab

    save file identifier [[PDB_ID] selection]

Arguments
    *   ``file`` - file name
    *   ``identifier`` - module-internal entity identifier
    *   ``PDB_ID`` - four-character code used as PDB identifier, optional, defaults to PDB identifiert of loaded entity
    *   ``selection`` - optional, if present, only a selected part of the structure is saved, see :ref:`MMMx_addresses`
Remarks
    *   a minimal PDF file is saved	
	
``superimpose``
---------------------------------

Superimposes one structure onto another structure. The superposition can be defined by a subset of atom coordinates. 

.. code-block:: matlab

    superimpose moving template [directive_1 [directive_2]] 

Arguments
    *   ``moving`` - module-internal entity identifier of the structure whose coordinates are transformed 
    *   ``template`` - module-internal entity identifier of the structure that serves as a template
    *   ``directive_1`` - optional directive that specifies how the superposition takes place (see Remarks)
    *   ``directive_2`` - another optional directive that specifies how the superposition takes place (see Remarks)
Remarks
    *   the coordinates of the atoms specified by template fields and by directives are least-square superimposed on corresponding template coordinates	    
    *   by default, residue numbers are assumed to match in moving and template structure, directive ``align`` matches residues by sequence alignment instead   
    *   by default, backbone atoms are superimposed, directive ``CA`` superimposes only C :math:`\alpha` atoms, directive ``C4'`` only C4' atoms of nucleotides, and directive ``all`` all atoms 	    
    *   part of the moving and template strucure can be selected by subfields, for instance ``BtuCDF.(F)`` selects only chain F of entity BruCDF for superposition, ``BtuCDF.(F)147-238`` only residues 147-238 of this chain
    *   selection is possible only down to residue level, not atom level
    *   the whole structure moves, but only the selected part is least-squares superimposed

``symmetry``
---------------------------------

Transform coordinates to a symmetry frame. This is a block key with `n` lines for an `n`-fold symmetry axis. 

.. code-block:: matlab

    symmetry mode identifier
       'address_1'
       []
       'address_n'
    .symmetry

Arguments
    *   ``mode`` - superposition mode, can be `backbone` or `CA` or `C4'` or `all`
    *   ``identifier`` - module-internal entity identifier
    *   ``address_1`` address of chain, e.g. `(A)` or residue range, e.g., `(A)58-108` in the first protomer
    *   ``address_n`` address of chain or residue range in the last protomer
Remarks
    *   the addresses together with the mode define the atoms that are superimposed by minimal rmsd 
    *   the result is not automatically saved, use ``save`` if necessary
    *   the `C_n` symmetry axis becomes the new `z` axis
