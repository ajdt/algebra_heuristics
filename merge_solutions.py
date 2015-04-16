import sys
import json

first_file, snd_file, result_file = sys.argv[1:]
def getJSONObjectFromFile(file_name):
    file_obj = file(file_name, 'r')
    input_string = file_obj.read()
    json_obj = json.loads(input_string)
    file_obj.close()
    return json_obj
def mergeJSONObjects(fst_obj, snd_obj):
    # XXX: just merges two witness lists, so other data like 'Models', 'Result', 'Time'
    # is inaccurate. This is fine b/c I don't use this data in visualizer

    # add witnesses for second object
    snd_obj_witnesses = snd_obj['Call'][0]['Witnesses']
    # XXX: hacky, append only the first witness (there should be only one)
    fst_obj['Call'][0]['Witnesses'].append(snd_obj_witnesses[0])
    return fst_obj

def writeObjectToJSONFile(obj, file_name):
    file_obj = file(file_name, 'w')
    file_obj.write(json.dumps(obj))
    file_obj.close()

fst_obj         = getJSONObjectFromFile(first_file)
snd_obj         = getJSONObjectFromFile(snd_file)
new_json_obj    = mergeJSONObjects(fst_obj, snd_obj)
writeObjectToJSONFile(new_json_obj, result_file)

#print json_obj['Call'][0]['Witnesses'].__class__
#return decoded_output['Call'][0]['Witnesses'] 
