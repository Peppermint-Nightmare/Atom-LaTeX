pkg = require '../lib/main'
helper = require './helper'
path = require 'path'

describe 'Atom-LaTeX', ->
  beforeEach ->
    waitsForPromise ->
      return helper.activatePackages()

  describe 'Package', ->
    describe 'when package initialized', ->
      it 'has Atom-LaTeX main object', ->
        expect(pkg.latex).toBeDefined()
        expect(pkg.latex.builder).toBeDefined()
        expect(pkg.latex.manager).toBeDefined()
        expect(pkg.latex.viewer).toBeDefined()
        expect(pkg.latex.server).toBeDefined()
        expect(pkg.latex.logPanel).toBeDefined()
        expect(pkg.latex.parser).toBeDefined()

  describe 'Builder', ->
    describe 'build-after-save feature', ->
      builder = builder_ = undefined

      beforeEach ->
        builder = jasmine.createSpyObj 'Builder', ['build']
        builder_ = pkg.latex.builder
        pkg.latex.builder = builder

        project = """#{path.dirname(__filename)}#{path.sep}latex_project"""
        atom.project.setPaths [project]
        pkg.latex.mainFile = """#{project}#{path.sep}main.tex"""

      afterEach ->
        pkg.latex.builder = builder_
        helper.restoreConfigs()

      it 'compile if current file is a .tex file', ->
        helper.setConfig 'atom-latex.build_after_save', true
        project = """#{path.dirname(__filename)}#{path.sep}latex_project"""
        waitsForPromise -> atom.workspace.open(
          """#{project}#{path.sep}input.tex""").then (editor) ->
            editor.save()
            expect(builder.build).toHaveBeenCalled()

      it 'does nothing if config disabled', ->
        helper.setConfig 'atom-latex.build_after_save', false
        project = """#{path.dirname(__filename)}#{path.sep}latex_project"""
        waitsForPromise -> atom.workspace.open(
          """#{project}#{path.sep}input.tex""").then (editor) ->
            editor.save()
            expect(builder.build).not.toHaveBeenCalled()

      it 'does nothing if current file is not a .tex file', ->
        helper.setConfig 'atom-latex.build_after_save', true
        project = """#{path.dirname(__filename)}#{path.sep}latex_project"""
        waitsForPromise -> atom.workspace.open(
          """#{project}#{path.sep}non_tex.file""").then (editor) ->
            editor.save()
            expect(builder.build).not.toHaveBeenCalled()

    describe 'toolchain feature', ->
      binCheck = binCheck_ = undefined

      beforeEach ->
        binCheck_ = pkg.latex.builder.binCheck
        spyOn(pkg.latex.builder, 'binCheck')

        project = """#{path.dirname(__filename)}#{path.sep}latex_project"""
        atom.project.setPaths [project]
        pkg.latex.mainFile = """#{project}#{path.sep}main.tex"""

      afterEach ->
        pkg.latex.builder.binCheck = binCheck_
        helper.restoreConfigs()

      it 'generates latexmk command when enabled auto', ->
        helper.setConfig 'atom-latex.toolchain', 'auto'
        helper.unsetConfig 'atom-latex.latexmk_param'
        pkg.latex.builder.binCheck.andReturn(true)
        pkg.latex.builder.setCmds()
        expect(pkg.latex.builder.cmds[0]).toBe('latexmk -synctex=1 \
          -interaction=nonstopmode -file-line-error -pdf main')

      it 'generates custom command when enabled auto but without binary', ->
        helper.setConfig 'atom-latex.toolchain', 'auto'
        helper.unsetConfig 'atom-latex.compiler'
        helper.unsetConfig 'atom-latex.bibtex'
        helper.unsetConfig 'atom-latex.compiler_param'
        helper.unsetConfig 'atom-latex.custom_toolchain'
        pkg.latex.builder.binCheck.andReturn(false)
        pkg.latex.builder.setCmds()
        expect(pkg.latex.builder.cmds[0]).toBe('pdflatex -synctex=1 \
          -interaction=nonstopmode -file-line-error main')
        expect(pkg.latex.builder.cmds[1]).toBe('bibtex main')

      it 'generates latexmk command when enabled latexmk toolchain', ->
        helper.setConfig 'atom-latex.toolchain', 'latexmk toolchain'
        helper.unsetConfig 'atom-latex.latexmk_param'
        pkg.latex.builder.binCheck.andReturn(true)
        pkg.latex.builder.setCmds()
        expect(pkg.latex.builder.cmds[0]).toBe('latexmk -synctex=1 \
          -interaction=nonstopmode -file-line-error -pdf main')

      it 'generates custom command when enabled custom toolchain', ->
        helper.setConfig 'atom-latex.toolchain', 'custom toolchain'
        helper.unsetConfig 'atom-latex.compiler'
        helper.unsetConfig 'atom-latex.bibtex'
        helper.unsetConfig 'atom-latex.compiler_param'
        helper.unsetConfig 'atom-latex.custom_toolchain'
        pkg.latex.builder.binCheck.andReturn(false)
        pkg.latex.builder.setCmds()
        expect(pkg.latex.builder.cmds[0]).toBe('pdflatex -synctex=1 \
          -interaction=nonstopmode -file-line-error main')
        expect(pkg.latex.builder.cmds[1]).toBe('bibtex main')


  describe 'Manager', ->
    describe '::fileMain', ->
      it 'should return false when no main file exists in project root', ->
        pkg.latex.mainFile = undefined
        project = """#{path.dirname(__filename)}"""
        atom.project.setPaths [project]
        result = pkg.latex.manager.findMain()
        expect(result).toBe(false)
        expect(pkg.latex.mainFile).toBe(undefined)

      it 'should set main file full path when it exists in project root', ->
        pkg.latex.mainFile = undefined
        project = """#{path.dirname(__filename)}#{path.sep}latex_project"""
        atom.project.setPaths [project]
        result = pkg.latex.manager.findMain()
        relative = path.relative(project, pkg.latex.mainFile)
        expect(result).toBe(true)
        expect(pkg.latex.mainFile).toBe("""#{project}#{path.sep}main.tex""")