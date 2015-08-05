#!/usr/bin/env python
import argparse
import os.path
import sys
import yaml
import re
import glob
import jinja2
import difflib


def dockerfile_template_path(ctx):
    tpl_list = filter(None, ("Dockerfile.template", ctx['variant']))
    filepath = '-'.join(tpl_list)
    # Abort if template not found, this is misconfiguration.
    if not os.path.isfile(filepath):
        print("Error: template file `{}' not found!".format(filepath))
        sys.exit(1)
    return filepath


def dockerfile_path(ctx):
    tgt_list = filter(None, (ctx['suite'], ctx['variant'], 'Dockerfile'))
    return '/'.join(tgt_list)


def template_exists(basepath='', abort=False):
    template_path = os.path.join(basepath, 'Dockerfile.template')
    exists = os.path.isfile(template_path)
    if not exists and abort is True:
        print("Error: {} file not found!".format(template_path))
        sys.exit(1)
    return exists


class UpdateCLI(object):
    CLIDESC = """Generate Dockerfile(s) from suite template files.
    """

    def __init__(self):
        self.parser = argparse.ArgumentParser(description=self.CLIDESC)
        self.options = {}
        self.arguments = {}

    def parse(self):
        self.parser.add_argument('image', nargs='?',
                                 help='Path to an image directory containing Dockerfile.template.')
        self.parser.add_argument('suites', metavar='suite', nargs='*',
                                 help='Specifies a list of suites to work on.')
        self.arguments = vars(self.parser.parse_args())
        return self.arguments

    def process_options(self):
        """Process options, parse command line arguments and construct an
        options hash.
        """
        self.parse()

        image = self.arguments['image']
        suites = self.arguments['suites']

        if image:
            if template_exists(basepath=image):
                image_dir = os.path.abspath(image)

            # first argument is a suite
            elif template_exists():
                image_dir = os.getcwd()
                suites.insert(0, os.path.basename(image_dir))
            else:
                template_exists(basepath=image, abort=True)

        # no arguments given, so we must be inside a directory with a suite template.
        else:
            template_exists(abort=True)

        self.options = {
            'image_dir': image_dir,
            'suites': suites
        }
        return self.options


class Suite(object):
    def __init__(self, workdir, suites):
        self.distmap_cache = {}
        self.workdir = workdir
        self.image = os.path.basename(os.path.abspath(workdir))
        self.suites = suites
        self.variants = [None]
        self.registry = None
        self.latest = None
        self.load_suite_config()

    def load_suite_config(self):
        confpath = os.path.join(self.workdir, 'suite.yml')
        if os.path.isfile(confpath):
            fd = open(confpath, 'r')
            for opt, value in yaml.load(fd).items():
                if value:
                    setattr(self, opt, value)
            fd.close()

    def load_distmap(self):
        """Looks up dist.yml starting in the current directory and up the tree,
        if it's found returns its content.
        """
        found = None
        path = os.getcwd()
        while path != '/':
            ymlpath = os.path.join(path, 'dist.yml')
            if ymlpath in self.distmap_cache:
                return self.distmap_cache[ymlpath]
            if os.path.isfile(ymlpath):
                found = True
                break
            path = os.path.dirname(path)
        if not found:
            print("Error: file `dist.yml' not found in current or its parent directories!")
            sys.exit(1)

        fd = open(ymlpath, 'r')
        data = yaml.load(fd)
        fd.close()
        self.distmap_cache[ymlpath] = data
        return data

    def process(self):
        yaml.add_constructor('!regexp', lambda l, n: re.compile(l.construct_scalar(n)))

        curd = os.getcwd()
        os.chdir(self.workdir)

        # Specific suites haven't been set, so list all directories
        if not self.suites:
            self.suites = (s.rstrip('/') for s in glob.glob('*/'))

        for suite in self.suites:
            for variant in self.variants:
                # Check if variant supports only specific suites and skip
                if isinstance(variant, dict):
                    variant, suites = variant.items()[0]
                    if suite not in suites:
                        continue
                yield(self.suite_context(suite, variant))

        os.chdir(curd)

    def suite_context(self, suite, variant):
        """Return context of a process suite. Hash of variables.
        """
        dist, version = self.find_distver(suite)
        return {
            'suite': suite,
            'variant': variant,
            'dist': dist,
            'version': version,
            'image': self.image,
            'registry': self.registry or ''
        }

    def find_distver(self, suite):
        """Find dist and its version by a suite name. Uses mappings from dist.yaml.
        """
        retype = type(re.compile('hello, world'))
        for dist, mappings in self.load_distmap().items():
            for imap in mappings:
                if imap == suite:
                    return (dist, suite)
                elif isinstance(imap, retype):
                    m = re.match(imap, suite)
                    if m:
                        return (dist, m.group(1) or suite)
        print("Warn: suite to dist mapping not found! Check dist.yml for `{}' mapping."
              .format(suite))


def main():
    """Reads Dockerfile.template* files and genterates corresponding Dockerfile files.
    """
    cli = UpdateCLI()
    opts = cli.process_options()
    sp = Suite(workdir=opts['image_dir'], suites=opts['suites'])

    for ctx in sp.process():
        j2env = jinja2.Environment(loader=jinja2.FileSystemLoader('./'))
        target_filepath = dockerfile_path(ctx)
        filepath = dockerfile_template_path(ctx)
        template = j2env.get_template(filepath)
        rendered = template.render(ctx)

        mode = 'r+' if os.path.isfile(target_filepath) else 'w+'
        fd = open(target_filepath, mode)
        current = fd.read().splitlines()
        fd.seek(0)
        fd.truncate()

        abspath = os.path.abspath(target_filepath)
        for line in difflib.unified_diff(current, rendered.splitlines(),
                                         fromfile=abspath + '.~',
                                         tofile=abspath,
                                         lineterm='', n=0):
            print line

        fd.write("{}\n".format(rendered))
        fd.close()


if __name__ == '__main__':
    main()
