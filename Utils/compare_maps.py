from bs4 import BeautifulSoup
from os import path

import sys
import getopt

folder = ""
base_fn = ""
ref_fn = ""
out_fn = ""

count_only = False
list_missing = False

normal = []
low_res = []
result = []

try:
    opts, args = getopt.getopt(sys.argv[1:], "clh", ["folder=", "base=", "ref=", "out="])
except getopt.GetoptError:
    print("Unsupported option!")
    sys.exit()

valid_count = 0
for opt, arg in opts:
    if opt == '--folder':
        folder = arg
        valid_count += 1
    elif opt == '--base':
        base_fn = arg
        valid_count += 1
    elif opt == '--ref':
        ref_fn = arg
        valid_count += 1
    elif opt == '--out':
        out_fn = arg
        valid_count += 1
    elif opt == '-c':
        count_only = True
    elif opt == '-l':
        list_missing = True
    elif opt == '-h':
        print("""<Options>
        --folder [folder]   : The folder where the files are located
        --base [filename]   : The base SVG with low-resolution data
        --ref [filename]    : The reference SVG with standard resolution data
        --output [filename] : The SVG where to save the spliced mapa date

        -c                  : Only count missing countries without writing to file
        -l                  : List the names of the missing countries
        -h                  : Display this help
        """)

# print(valid_count == 4)
# sys.exit()
if valid_count < 4:
    print("Missing required arguments!")
    sys.exit()

try:
    r_path = path.abspath(folder + "/" + ref_fn)
    l_path = path.abspath(folder + "/" + base_fn)
    with open(r_path, "r") as r_file:
        with open(l_path, "r") as l_file:
            # parse low res
            l_countries = BeautifulSoup(l_file, 'xml')

            # list low res country ids
            for c in l_countries.find_all('path'):
                low_res.append(c['id'])

            print(len(low_res))

            # parse regular res
            r_countries = BeautifulSoup(r_file, 'xml')

            # list regular res country ids
            for c in r_countries.find_all('path'):
                normal.append(c['id'])

            print (len(normal))

            # country is missing if in regular res but not low res
            def missing(s):
                return not (s in low_res)

            # filter missing countries
            filtered = filter(missing, normal)

            # def extract(elt):
            #     return elt['id'] in filtered

            # collect regular res missing country elts in list
            for f in filtered:
                result.append(r_countries.find(id=f))
                if list_missing:
                    print(f)

            print(len(result))

            if not count_only:
                with open(folder + "/" + out_fn, "w") as spliced:
                    # grab low res root
                    def find_root(id):
                        return id == 'ne_countries'

                    root_maybe = l_countries.find_all('g')
                    root = None

                    for g in root_maybe:
                        if g.has_attr('id'):
                            root = g
                            break

                    print(root['id'])

                    # sanity check
                    print(len(root.find_all('path')))

                    # append regular res missing countries
                    for elt in result:
                        root.append(elt)

                    # sanity check
                    print(len(root.find_all('path')))

                    # write to file!
                    print("Writing to file...")
                    spliced.write(l_countries.prettify())

            print("Done! :)")
except IOError as e:
    print ("Something went wrong...")
    print (e)
