# sugeno
This project is an enhancement of an anomaly detection method originally published [here](https://scholar.google.com/scholar?oi=bibs&cluster=2172194093366122252&btnI=1&hl=en).

The original method is based on a combination of the theories of fuzzy sets, integral Sugeno, and kernel trick and essentially belongs to a class of _unsupervised_ ML algo.

Here we present an approach that allows for application of this method to a _supervised_ ML tasks, like classification or regression. Check out a python/sugeno.ipynb jupyter notebook for details.

The core idea of the method is based on the notion of a _membership_ function. For each object of the input sample the method assigns a number in \(0, 1\) which is called membership and has a meaning of how typical such an object with respect to a previously calculated _center_ of the entire input sequence. The more the value of the membership function is, the more the object is "typical".

Now let us turn to a labelled data. Take for example the iris data set. If we apply such an approach to a single type of iris (say, _Setosa_) then we might expect that instances of the same type would be more "typical" compared the other two classes (_Virginica_ and _Versicolour_). Thus we might expect membership is having a discriminative power, can treat it as a new _feature_ and add it to the input of a learning algo.

We might want to continue this way and add memberships with respect to the remaining two iris classes, thus adding three new features to the input data set.

To test the approach we split the entire iris data set to two parts: training and testing, 50% each. Then we calculate a membership function with respect to a chosen iris type, say _Versicolour_. The resulting five-dimensional data set is trained with [_AdaBoostClassifier_](http://scikit-learn.org/stable/modules/generated/sklearn.ensemble.AdaBoostClassifier.html) model and then applied to the testing part (for which we also calculate memberships first). 

We then compare the results with a membership feature removed. Obviously, for such a small data set improvement of performace may look inconclusive, but this is done for purely demonstration purposes to present an idea which might be applicable to other not so trivial situations.


Here are the results on a testing data set.

No membership feature:


|pred/act|0	   |1	   |2    |
|:-------|----:|----:|----:|
|0	     |28	 |0	   |0    |
|1	     |0	   |  13 |5    |
|2	     |  0	 |  0	 |  29 | 


Membership wrt Versicolour included:


|pred/act|0	   |1	   |2    |
|:-------|----:|----:|----:|
|0	     |  28 |0	   |0    |
|1	     |  0	 |  17 |1    |
|2	     |  0	 |  1	 |  28 | 

The model reports importance of the newly included membership feature as being = 20%

## Visualization

The original method also allows for calculation of projection of the entire feature space to a space of smaller dimension via _kernel PCA_. In many cases it can give a "visual" sense of quality of classification:

![alt text](https://github.com/slava-mazur/sugeno/blob/master/img/center-versicolor.png "Center Versicolour")

An interactive version of this 3D chart is available [here](https://plot.ly/~slava-mazur/8/_0-1-2/).
