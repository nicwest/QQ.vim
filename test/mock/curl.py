import sys


def main(*args, **kwargs):
    sys.stdout.write(str(sys.argv[1:])+'\n')

if __name__ == '__main__':
    main()
