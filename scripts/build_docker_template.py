#!/usr/bin/python3

import json, os, sys, re

TPL = {}

def read_template_config(config):
    with open(config, 'r') as f:
        return json.loads(f.read())

def apply_template(template_file, config):
    re_tpl = re.compile('(?P<tpl>\<\!template=(?P<key>[^\>]+)\>)')
    result = []

    with open(template_file, 'r') as f:
        for line in f:
            result.append(re_tpl.sub(sub_template, line.rstrip()))
    
    return '\n'.join(result)

def sub_template(match):
    grp, *keys = match.groupdict()['key'].split('.')
    repstr = get_config_value_from_key_list(TPL['config'][grp], keys)

    if isinstance(repstr, list):
        return templify_list(repstr)
    elif isinstance(repstr, dict):
        if grp == 'mxe':
            return templify_make_dict(repstr)

    return repstr

def get_config_value_from_key_list(grp, keys):
    tmp = grp
    for k in keys:
        if not k in tmp:
            raise Exception(f"Key not found in json config: {'.'.join(keys)}")
        tmp = tmp[k]
    return tmp

def templify_list(value):
    return ' '.join(value).replace(' ', ' \\\n\t').rstrip()

def templify_make_dict(value):
    return ' '.join([k + '=' + v for k,v in value.items()])

def main(args):
    if len(args) < 2:
        print("Usage: build_docker_template.py <Dockerfile template> <config>")

    global TPL
    TPL['docker'] = args[0]
    TPL['config'] = read_template_config(args[1])

    output_file = TPL['docker'].removesuffix('.template')
    templated = apply_template(TPL['docker'], TPL['config'])

    with open(output_file, 'w') as f:
        f.write(templated)
    
    print(f'Dockerfile created: {output_file}')


if __name__ == "__main__":
    main(sys.argv[1:])
