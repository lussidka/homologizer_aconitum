Treat this as a collaborative software engineering project rather than a one-shot code generation task.

# Prompt for AI Agent

This workspace contains all files required to create a Snakemake workflow for the project described in `n_PPSK4_177_project_description.md`.

Your first task is to inspect all provided files, documents, template files, and create a detailed implementation plan.

At this stage, your task is limited to Phase 1 only.

Do not start implementing any code, Snakemake rules, or helper scripts until Phase 1 has been reviewed and approved.

Whenever you make an assumption, explicitly state it. Never make silent assumptions.

## Instructions

1. Read `n_PPSK4_177_project_description.md` completely.
2. Inspect every example file in the repository.
3. Determine how all files are connected.
4. Identify all required input files, intermediate files, generated scripts, and final outputs.
5. Infer the complete workflow from the provided examples.
6. Identify any ambiguities or missing information.

## Development strategy

Implement the workflow incrementally.

Split the implementation into small, independent phases.

After completing each phase:

1. Stop.
2. Summarize what has been implemented.
3. Explain any design decisions.
4. List the files that were created or modified.
5. Wait for my approval before continuing.

Do not continue automatically to the next phase.

Phase 1
- Inspect all template files.
- Understand the workflow.
- Produce analysis_plan.md.

Phase 2
- Generate sample-specific NEX files.
- Verify that the generated files match the provided templates.

Phase 3
- Generate RevBayes scripts for all tested ploidies.
- Verify that the generated scripts follow the template.

Phase 4
- Implement Snakemake rules for running RevBayes.
- Capture terminal output into log files.

Phase 5
- Parse Stepping Stone outputs.
- Extract likelihood values.
- Append results to the summary table.

Phase 6
- Calculate mean likelihoods.
- Determine the optimal ploidy.
- Generate warnings.

Phase 7
- Integrate all previous phases into Snakefile_part1.
- Test the dependency graph.
- Review the final workflow.


If you discover that a future phase requires changes to an earlier phase, stop and explain the required modifications instead of silently changing previous work.The proposed phases are an initial suggestion.

If you identify a better implementation order after analysing the repository, explain your reasoning and propose an updated phase structure before proceeding.

A phase is considered complete only if:

- all planned files have been created;
- the implementation is internally consistent;
- the expected outputs have been produced;
- no known issues remain undocumented.

At the end of every phase, include:

- completed work
- created or modified files
- remaining questions
- potential risks
- recommendation for the next phase

## Expected output

Create a file named:

"analysis_plan.md"

The plan should contain:

* an overview of the complete workflow
* a dependency graph of all workflow steps
* all expected input files
* all intermediate files
* all generated scripts
* all expected output files
* the order in which the Snakemake rules should be executed
* proposed directory structure
* possible helper scripts that should be created
* any assumptions or ambiguities that require clarification

Split the workflow into small, well-defined implementation phases.

For each phase, describe:

* objective
* inputs
* outputs
* Snakemake rules that should be implemented
* helper scripts that will be required
* expected deliverables

## Requirements

The final implementation should:

* be modular
* be scalable to approximately 170 samples
* use Snakemake wildcards wherever possible
* avoid duplicated code
* generate descriptive filenames
* reuse the provided template files instead of rewriting them

## Approval step

Do not implement anything until the implementation plan has been reviewed and approved.

Only after approval should the implementation of "Snakefile_part1" begin.


## goal

The goal is not only to generate working Snakefiles.

The generated workflows should be modular, easy to extend, and suitable for future analyses involving approximately 170 samples without requiring changes to the workflow structure.

When multiple implementation options are possible, choose the solution that is most consistent with Snakemake best practices and explain why it was selected.

## Existing files

The repository already contains:

- example NEXUS files
- example RevBayes scripts
- example Stepping Stone outputs
- helper documentation (homologizer_navod.md)

These files are provided as templates only.

Do not modify them.

Instead, generate new files based on these templates.

## Template analysis

Before proposing the workflow, analyse every template file and explain:

- which parts are constant
- which parts must be replaced dynamically
- which values come from the metadata table
- which filenames must be generated automatically

