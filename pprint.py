import sys
import json
import xml.dom.minidom as xml


def _json(infile, outfile):
    try:
        obj = json.load(infile)
    except ValueError, e:
        raise SystemExit(e)
    json.dump(obj, outfile, sort_keys=True, indent=4, separators=(',', ': '))


def _xml(infile, outfile):
    try:
        obj = xml.parse(infile)
    except ValueError, e:
        raise SystemExit(e)
    pretty_xml_as_string = obj.toprettyxml()
    outfile.write(pretty_xml_as_string)


def main():
    filetype = sys.argv[1]
    infile = open(sys.argv[2], 'rb')
    outfile = sys.stdout
    if filetype == 'javascript':
        _json(infile, outfile)
    if filetype == ['html', 'xml']:
        _xml(infile, outfile)
    else:
        outfile.write(infile.read())

if __name__ == '__main__':
    main()
