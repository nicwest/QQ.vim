import sys
import json
import xml.dom.minidom as xml


def _json(infile, outfile):
    try:
        obj = json.load(infile)
    except ValueError as e:
        raise SystemExit(e)
    json.dump(obj, outfile, sort_keys=True, indent=4, separators=(',', ': '))


def _xml(infile, outfile):
    try:
        obj = xml.parse(infile)
    except Exception as e:
        raise SystemExit(e)
    pretty_xml_as_string = obj.toprettyxml()
    outfile.write(pretty_xml_as_string)


def main():
    filetype = sys.argv[1]
    infile = open(sys.argv[2], 'rb')
    outfile = sys.stdout
    if filetype in ['javascript']:
        _json(infile, outfile)
    elif filetype in ['html', 'xml']:
        _xml(infile, outfile)
    else:
        outfile.write(infile.read())

if __name__ == '__main__':
    main()
