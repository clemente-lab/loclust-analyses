#!/usr/bin/env python
from __future__ import division, print_function

import click
import sys
import os
from collections import defaultdict
import numpy as np
import difflib as dl
from lodi.parse import read_trajectories, convert_clustering
from lodi.stats import NVI, hmg_cmplt_v_measure, f_measure, adjusted_rand_index
from lodi import __version__

__author__ = "David Wallach"
__copyright__ = "Copyright 2016, The Clemente Lab"
__credits__ = ["David Wallach", "Jose Clemente"]
__license__ = "GPL"
__maintainer__ = "David Wallach"
__email__ = "d.s.t.wallach@gmail.com"

CONTEXT_SETTINGS = dict(help_option_names=['-h', '--help'])


@click.command(context_settings=CONTEXT_SETTINGS)
@click.version_option(version=__version__)

@click.option('-i', '--file_fp', required=False,
              type=click.Path(exists=False),
              default="file.out",
              help='full path of directory  with tnput files with data: '\
              'columns are attributes, rows are samples')
@click.option('-o', '--out_fp', required=True,
              type=click.Path(exists=False),
              help='Output file to write trajectories')
@click.option('-d', '--directory', required=False,
              default='./',
              type=click.Path(exists=False),
              help='Directory files should be generated in')
@click.option('-s', '--simulation', is_flag=True,
              help='Pass when inputs are from simulation.')
@click.option('-k', '--true_key', required=False,
              default='original_trajectory',
              help='True label column.')
@click.option('-c', '--clean_up', required=False,
              is_flag=True, help='When set the output of simulate_trajectories will be cleared')
@click.option('-m', '--method', required=False,
              default='unkown', help='Method of clustering.')
def compare(out_fp, file_fp, directory, simulation, true_key, clean_up, method):
    """
    Compares clustering results from lodi against several R packages

    TSclust using clustering methods EUCL, DTWARP, and CID
    Will make use of lodi.util.lodi_system_call to call simulate_trajectories.py
    and then call cluster_trajectories.py.
    """
    
    # clusters.append(readInClusters(str(numberOfClusters) + "-means.out"))
    if os.path.isdir(file_fp):
        all_files = os.listdir(file_fp)
        files = list()
        for fp in all_files:
           if ".clust.tsv" in fp:
                files.append(fp)
    elif os.path.isfile(file_fp):
        files = [file_fp]
    else:
        sys.stderr.write('%s does not exist.\n') % file_fp
        return

    if not os.path.isfile(os.path.join(directory, out_fp)):
        f = open(os.path.join(directory, out_fp), 'w')
        f.write('method\texplained_varaince_ratio\tsubsample\tmodel\tmodel_num\tlabel\tnoise\trep_num\tNVI\tV_measure\tHomogeneity\tCompleteness\tF_measure\tAdjusted_Rand_Index\tk\n')
        f.close()
    else:
        sys.stderr.write('Output file exists. Writing after it...\n')
    for s in files:
        # Read in the TSclust clusterings
        data, rep, model, model_num, noise = readInLodi(os.path.join(file_fp, s), simulation)
        # Compare the results of the various clustering methods
        compareResults(data, rep, model, model_num, noise, os.path.join(directory, out_fp), method, true_key)    
    return



def compareResults(data, rep, model, model_num, noise, fp, method, true_key='original_trajectory'):
    """
    Compare the results of the various clustering methods
    using X analysis.
    """
    dat = {'cluster': data['cluster']}
    k = len(set(data['cluster']))
    exp_var = 'NA'
    if 'explained_varaince_ratio' in data:
        exp_var = data['explained_varaince_ratio'][0]
    subsample = 'NA'
    if 'subsample' in data:
        subsample = data['subsample'][0]
    keys = [true_key]
    for key in keys:
        dat['original_trajectory'] = list(data[key])
        try:
            nvi = NVI(dat['original_trajectory'], dat['cluster'])
        except ValueError:
            nvi = np.nan
        try:
            f_m = f_measure(dat)
        except ValueError:
            f_m = np.nan
        try:
            homogeneity, completeness, v_m = hmg_cmplt_v_measure(dat)
        except ValueError:
            homogeneity, completeness, v_m = np.nan, np.nan, np.nan
        try:
            a_rand = adjusted_rand_index(dat)
        except ValueError:
            a_rand = np.nan
        sys.stderr.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (method,
                                                                           exp_var,
                                                                           subsample,
                                                                           model, 
                                                                           model_num, 
                                                                           true_key, 
                                                                           noise, 
                                                                           rep, 
                                                                           nvi,
                                                                           v_m, 
                                                                           homogeneity, 
                                                                           completeness,
                                                                           f_m, 
                                                                           a_rand,
                                                                           k))
        f = open(fp, 'a')
        f.write('%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (method,
                                                                           exp_var,
                                                                           subsample,
                                                                           model, 
                                                                           model_num, 
                                                                           true_key, 
                                                                           noise, 
                                                                           rep, 
                                                                           nvi,
                                                                           v_m, 
                                                                           homogeneity, 
                                                                           completeness,
                                                                           f_m, 
                                                                           a_rand,
                                                                           k))
        f.close()


def readInLodi(file_fp, simulation):
    """
    Reads in the output of evaluate_clustering.py and parses the data.
    Returns a list of clusters in order of the trajectories analyzed
    """
    sys.stderr.write('...reading data\n')
    trajs = read_trajectories(file_fp)
    data = defaultdict(list)
    mheader = trajs[0].mdata.keys()
    for t in trajs:
        for k in mheader:
            data[k].append(t.mdata[k])
    if simulation:
       fname = file_fp.split('/')[-1]
       params = fname.split('.')
       rep = params[-3]
       if not rep.isdigit():
           rep = params[-4]
       model = params[2]
       model_num = model.count('-') + 1
       noise = fname.split('noise')[0]
    else:
       fname = file_fp.split('/')[-1]
       params = fname.split('.')
       rep = params[-3]
       if not rep.isdigit():
           rep = params[-4]
       model = data['taxa'][0]
       model_num = 1
       noise = 0
    return data, rep, model, model_num, noise



if __name__ == "__main__":
    compare()
