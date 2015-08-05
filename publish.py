#!/usr/bin/env python
import os.path
import sys
import subprocess
import copy

scriptdir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(scriptdir)

from update import UpdateCLI, Suite, dockerfile_path
from string import maketrans


class PublishCLI(UpdateCLI):
    CLIDESC = """Generate Dockerfile(s) from suite template files.
    """

    def parse(self):
        self.parser.add_argument('--rm', action='store_true',
                                 help='Remove intermediate containers after a successful build.')
        self.parser.add_argument('--no-cache', action='store_true',
                                 help='Do not use cache when building the image.')
        self.parser.add_argument('--no-push', action='store_true',
                                 help='Do not use cache when building the image.')
        super(PublishCLI, self).parse()


def shell_out(command):
    return subprocess.call(command, shell=True)


def main():
    """Reads suite Dockerfile files
    """
    dashtbl = maketrans('_', '-')
    cli = PublishCLI()
    opts = cli.process_options()
    args = cli.arguments
    suite = Suite(workdir=opts['image_dir'], suites=opts['suites'])

    build_args = ['no_cache', 'rm']
    build_opts = ('--{}'.format(a.translate(dashtbl)) for a in build_args if args[a])
    build_opts = ' '.join(build_opts)

    tag_fmt = '{registry}{image}:{suite}{variant}'
    build_cmd = "docker build {options} -f {path} -t {tag}"
    taglatest_cmd = "docker tag -f {tag} {registry}{image}:latest"
    push_cmd = "docker push {tag}"

    for _ctx in suite.process():
        v = _ctx['variant']
        ctx = copy.copy(_ctx)
        ctx['variant'] = '' if v is None else '-{}'.format(v)
        tag = tag_fmt.format(**ctx)

        # Run docker build
        shell_out('echo ' + build_cmd.format(path=dockerfile_path(_ctx),
                                             tag=tag,
                                             options=build_opts))

        # Tag latestest if suite.yml contains latest option
        if ctx['suite'] + ctx['variant'] == suite.latest:
            shell_out('echo ' + taglatest_cmd.format(registry=ctx['registry'],
                                                     image=ctx['image'],
                                                     tag=tag))

        # Push image
        if not args['no_push']:
            shell_out('echo ' + push_cmd.format(tag=tag))


if __name__ == '__main__':
    main()
